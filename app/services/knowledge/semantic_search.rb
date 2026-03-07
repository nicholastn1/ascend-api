module Knowledge
  class SemanticSearch
    EMBEDDING_MODEL = ENV.fetch("EMBEDDING_MODEL", "text-embedding-3-small")
    EMBEDDING_DIMENSIONS = ENV.fetch("EMBEDDING_DIMENSIONS", 768).to_i
    DEFAULT_LIMIT = 5
    MAX_CONTEXT_LENGTH = 4000 # Max chars of context to return

    # Search the knowledge base for relevant content.
    # Returns array of { chunk_text:, distance:, document_title:, document_type: }
    def self.search(query:, user: nil, limit: DEFAULT_LIMIT)
      new.search(query: query, user: user, limit: limit)
    end

    # Build a context string for RAG injection into chat prompts
    def self.build_context(query:, user:, limit: DEFAULT_LIMIT)
      new.build_context(query: query, user: user, limit: limit)
    end

    def search(query:, user: nil, limit: DEFAULT_LIMIT)
      # Generate query embedding
      response = RubyLLM.embed(query, model: EMBEDDING_MODEL, dimensions: EMBEDDING_DIMENSIONS)
      query_embedding = response.vectors

      # Search via pgvector
      raw_results = VectorSearch.search(query_embedding: query_embedding, limit: limit * 2)

      # Hydrate with chunk metadata, optionally filter by user
      results = raw_results.filter_map do |row|
        chunk_id = row["chunk_id"]
        distance = row["distance"]

        chunk = EmbeddingChunk.find_by(id: chunk_id)
        next unless chunk

        # Filter by user if specified
        if user
          case chunk.document_type
          when "KnowledgeDocument"
            doc = KnowledgeDocument.find_by(id: chunk.document_id)
            next unless doc&.user_id == user.id
          when "Resume"
            doc = Resume.find_by(id: chunk.document_id)
            next unless doc&.user_id == user.id
          end
        end

        {
          chunk_text: chunk.chunk_text,
          distance: distance,
          document_title: doc&.respond_to?(:title) ? doc.title : doc&.name,
          document_type: chunk.document_type
        }
      end

      results.first(limit)
    end

    def build_context(query:, user:, limit: DEFAULT_LIMIT)
      results = search(query: query, user: user, limit: limit)
      return nil if results.empty?

      context_parts = results.map do |r|
        source = "#{r[:document_type].underscore.humanize}: #{r[:document_title]}"
        "[Source: #{source}]\n#{r[:chunk_text]}"
      end

      context = context_parts.join("\n\n---\n\n")

      # Truncate if too long
      if context.length > MAX_CONTEXT_LENGTH
        context = context[0...MAX_CONTEXT_LENGTH] + "\n... (truncated)"
      end

      context
    end
  end
end
