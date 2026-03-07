require "rails_helper"

RSpec.describe VectorSearch do
  before(:each) do
    VectorSearch.reset!
    VectorSearch.ensure_table!
  end

  after(:each) do
    VectorSearch.reset!
    # Clean up the separate vector database file
    path = Rails.root.join("storage", "test_vectors.sqlite3")
    FileUtils.rm_f(path)
  end

  let(:dimension) { VectorSearch::EMBEDDING_DIMENSIONS }

  describe ".insert and .search" do
    it "inserts vectors and finds nearest neighbors" do
      base = Array.new(dimension) { 0.0 }

      close_vec = base.dup.tap { |v| v[0] = 1.0; v[1] = 0.9 }
      far_vec = base.dup.tap { |v| v[0] = -1.0; v[1] = -0.9 }

      VectorSearch.insert(chunk_id: "close", embedding: close_vec)
      VectorSearch.insert(chunk_id: "far", embedding: far_vec)

      query = base.dup.tap { |v| v[0] = 1.0; v[1] = 1.0 }
      results = VectorSearch.search(query_embedding: query, limit: 2)

      expect(results.length).to eq(2)
      expect(results.first["chunk_id"]).to eq("close")
      expect(results.first["distance"]).to be < results.last["distance"]
    end
  end

  describe ".delete" do
    it "removes a vector by chunk_id" do
      VectorSearch.insert(chunk_id: "test-del", embedding: Array.new(dimension) { rand })
      VectorSearch.delete(chunk_id: "test-del")

      results = VectorSearch.search(query_embedding: Array.new(dimension) { rand }, limit: 10)
      ids = results.map { |r| r["chunk_id"] }
      expect(ids).not_to include("test-del")
    end
  end

  describe ".delete_by_chunk_ids" do
    it "removes multiple vectors" do
      VectorSearch.insert(chunk_id: "a", embedding: Array.new(dimension) { rand })
      VectorSearch.insert(chunk_id: "b", embedding: Array.new(dimension) { rand })
      VectorSearch.insert(chunk_id: "c", embedding: Array.new(dimension) { rand })

      VectorSearch.delete_by_chunk_ids(%w[a b])

      results = VectorSearch.search(query_embedding: Array.new(dimension) { rand }, limit: 10)
      ids = results.map { |r| r["chunk_id"] }
      expect(ids).to eq([ "c" ])
    end
  end
end
