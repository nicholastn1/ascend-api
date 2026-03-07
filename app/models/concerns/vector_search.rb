module VectorSearch
  EMBEDDING_DIMENSIONS = ENV.fetch("EMBEDDING_DIMENSIONS", 768).to_i

  class << self
    def ensure_table!
      # pgvector table is managed by migrations; nothing to do at runtime
    end

    def reset!
      # No-op for pgvector (no separate connection to manage)
    end

    def insert(chunk_id:, embedding:)
      chunk = EmbeddingChunk.find_by(id: chunk_id)
      return unless chunk

      chunk.update_column(:embedding, Neighbor::Vector.new(embedding))
    end

    def delete(chunk_id:)
      chunk = EmbeddingChunk.find_by(id: chunk_id)
      chunk&.update_column(:embedding, nil)
    end

    def delete_by_chunk_ids(chunk_ids)
      return if chunk_ids.empty?

      EmbeddingChunk.where(id: chunk_ids).update_all(embedding: nil)
    end

    def search(query_embedding:, limit: 5)
      EmbeddingChunk
        .where.not(embedding: nil)
        .nearest_neighbors(:embedding, query_embedding, distance: :cosine)
        .limit(limit)
        .map { |chunk| { "chunk_id" => chunk.id, "distance" => chunk.neighbor_distance } }
    end
  end
end
