module Knowledge
  class EmbeddingService
    CHUNK_SIZE = 1000     # characters per chunk
    CHUNK_OVERLAP = 200   # overlap between chunks
    EMBEDDING_MODEL = ENV.fetch("EMBEDDING_MODEL", "text-embedding-3-small")
    EMBEDDING_DIMENSIONS = ENV.fetch("EMBEDDING_DIMENSIONS", 768).to_i
    BATCH_SIZE = 20       # max texts per embedding API call

    # Embed a document (KnowledgeDocument or Resume) by chunking its text
    # and storing embeddings in sqlite-vec.
    def self.embed_document(document)
      new.embed_document(document)
    end

    def self.remove_embeddings(document)
      new.remove_embeddings(document)
    end

    def embed_document(document)
      text = extract_text(document)
      return if text.blank?

      # Remove old chunks and embeddings
      remove_embeddings(document)

      # Chunk the text
      chunks = chunk_text(text)
      return if chunks.empty?

      # Create chunk records
      chunk_records = chunks.each_with_index.map do |chunk_text, index|
        document.embedding_chunks.create!(
          chunk_text: chunk_text,
          chunk_index: index
        )
      end

      # Generate embeddings in batches
      chunk_records.each_slice(BATCH_SIZE) do |batch|
        texts = batch.map(&:chunk_text)
        response = RubyLLM.embed(texts, model: EMBEDDING_MODEL, dimensions: EMBEDDING_DIMENSIONS)

        vectors = response.vectors
        # For single text, vectors is a flat array; for batch, it's array of arrays
        vectors = [ vectors ] if texts.length == 1 && !vectors.first.is_a?(Array)

        batch.each_with_index do |chunk, i|
          VectorSearch.insert(chunk_id: chunk.id, embedding: vectors[i])
        end
      end

      chunk_records.length
    end

    def remove_embeddings(document)
      chunks = document.embedding_chunks
      chunk_ids = chunks.pluck(:id)
      VectorSearch.delete_by_chunk_ids(chunk_ids) if chunk_ids.any?
      chunks.destroy_all
    end

    private

    def extract_text(document)
      case document
      when KnowledgeDocument
        document.content
      when Resume
        resume_to_text(document)
      else
        raise ArgumentError, "Unsupported document type: #{document.class}"
      end
    end

    def resume_to_text(resume)
      data = resume.data
      return "" unless data.is_a?(Hash)

      parts = []

      # Basics section
      if (basics = data["basics"])
        parts << "Name: #{basics["name"]}" if basics["name"].present?
        parts << "Headline: #{basics["headline"]}" if basics["headline"].present?
        parts << "Summary: #{basics["summary"]}" if basics["summary"].present?
        parts << "Location: #{basics["location"]}" if basics["location"].present?
        parts << "Email: #{basics["email"]}" if basics["email"].present?
        parts << "Phone: #{basics["phone"]}" if basics["phone"].present?
      end

      # Sections
      if (sections = data["sections"])
        sections.each do |key, section|
          next unless section.is_a?(Hash)

          section_name = section["name"] || key.humanize
          items = section["items"]
          next unless items.is_a?(Array) && items.any?

          parts << "\n#{section_name}:"
          items.each do |item|
            item_parts = item.values.select { |v| v.is_a?(String) && v.present? }
            parts << "  - #{item_parts.join(", ")}" if item_parts.any?
          end
        end
      end

      parts.join("\n")
    end

    def chunk_text(text)
      return [] if text.blank?
      return [ text.strip ] if text.length <= CHUNK_SIZE

      chunks = []
      pos = 0

      while pos < text.length
        chunk_end = [ pos + CHUNK_SIZE, text.length ].min

        # Try to break at a sentence or paragraph boundary
        if chunk_end < text.length
          break_zone_start = pos + (CHUNK_SIZE * 0.8).to_i
          break_point = text.rindex(/[.!?\n]/, chunk_end)

          if break_point && break_point >= break_zone_start
            chunk_end = break_point + 1
          end
        end

        chunk = text[pos...chunk_end]&.strip
        chunks << chunk if chunk.present?

        # Advance position with overlap, but always move forward
        next_pos = chunk_end - CHUNK_OVERLAP
        pos = [ next_pos, pos + 1 ].max
      end

      chunks
    end
  end
end
