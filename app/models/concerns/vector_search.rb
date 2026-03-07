# Manages the sqlite-vec virtual table for vector search.
#
# Uses a SEPARATE SQLite database (not the primary AR database) to avoid
# conflicts with ActiveRecord's connection management, transactions, and
# WAL-mode locking. This is critical for test compatibility and prevents
# DDL (CREATE VIRTUAL TABLE) from interfering with AR's transactional fixtures.
require "sqlite3"
require "sqlite_vec"

module VectorSearch
  EMBEDDING_DIMENSIONS = ENV.fetch("EMBEDDING_DIMENSIONS", 768).to_i

  class << self
    def ensure_table!
      connection.execute(<<~SQL)
        CREATE VIRTUAL TABLE IF NOT EXISTS vec_embeddings USING vec0(
          chunk_id TEXT PRIMARY KEY,
          embedding float[#{EMBEDDING_DIMENSIONS}]
        )
      SQL
    end

    def reset!
      Thread.current[:vector_search_connection]&.close rescue nil
      Thread.current[:vector_search_connection] = nil
    end

    def insert(chunk_id:, embedding:)
      ensure_table!
      blob = SQLite3::Blob.new(embedding.pack("f*"))
      connection.execute(
        "INSERT OR REPLACE INTO vec_embeddings(chunk_id, embedding) VALUES (?, ?)",
        [ chunk_id, blob ]
      )
    end

    def delete(chunk_id:)
      ensure_table!
      connection.execute(
        "DELETE FROM vec_embeddings WHERE chunk_id = ?",
        [ chunk_id ]
      )
    end

    def delete_by_chunk_ids(chunk_ids)
      return if chunk_ids.empty?

      ensure_table!
      placeholders = chunk_ids.map { "?" }.join(", ")
      connection.execute(
        "DELETE FROM vec_embeddings WHERE chunk_id IN (#{placeholders})",
        chunk_ids
      )
    end

    def search(query_embedding:, limit: 5)
      ensure_table!
      blob = SQLite3::Blob.new(query_embedding.pack("f*"))
      connection.results_as_hash = true
      results = connection.execute(
        "SELECT chunk_id, distance FROM vec_embeddings WHERE embedding MATCH ? ORDER BY distance LIMIT ?",
        [ blob, limit ]
      )
      results
    end

    private

    def connection
      # Thread-local connection for thread safety with SQLite
      Thread.current[:vector_search_connection] ||= begin
        db_path = vector_db_path
        FileUtils.mkdir_p(File.dirname(db_path))
        db = SQLite3::Database.new(db_path)
        db.enable_load_extension(true)
        SqliteVec.load(db)
        db.enable_load_extension(false)
        db.busy_timeout = 5000
        db
      end
    end

    def vector_db_path
      env = Rails.env
      base = ActiveRecord::Base.configurations.configs_for(env_name: env, name: "primary")&.database
      dir = base ? File.dirname(base) : "storage"
      File.join(dir, "#{env}_vectors.sqlite3")
    end
  end
end
