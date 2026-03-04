require "rails_helper"

RSpec.describe EmbeddingChunk, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:chunk_text) }
    it { is_expected.to validate_presence_of(:document_id) }
    it { is_expected.to validate_presence_of(:document_type) }
  end

  describe "UUID generation" do
    it "generates a UUID on create" do
      doc = create(:knowledge_document)
      chunk = doc.embedding_chunks.create!(chunk_text: "test content")
      expect(chunk.id).to match(/\A[0-9a-f-]{36}\z/)
    end
  end
end
