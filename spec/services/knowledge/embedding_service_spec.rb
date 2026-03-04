require "rails_helper"

RSpec.describe Knowledge::EmbeddingService do
  let(:user) { create(:user) }
  let(:dimensions) { VectorSearch::EMBEDDING_DIMENSIONS }

  before(:each) do
    VectorSearch.reset!
    VectorSearch.ensure_table!
  end

  after(:each) do
    VectorSearch.reset!
    path = Rails.root.join("storage", "test_vectors.sqlite3")
    FileUtils.rm_f(path)
  end

  describe "#embed_document" do
    context "with a KnowledgeDocument" do
      let(:document) { create(:knowledge_document, user: user, content: "This is a test document with enough content to embed.") }

      it "creates embedding chunks and stores vectors" do
        fake_vectors = [Array.new(dimensions) { rand(-1.0..1.0) }]
        fake_response = double("EmbeddingResponse", vectors: fake_vectors)
        allow(RubyLLM).to receive(:embed).and_return(fake_response)

        count = described_class.embed_document(document)

        expect(count).to be >= 1
        expect(document.embedding_chunks.count).to be >= 1
      end

      it "replaces existing embeddings on re-embed" do
        fake_vectors = [Array.new(dimensions) { rand(-1.0..1.0) }]
        fake_response = double("EmbeddingResponse", vectors: fake_vectors)
        allow(RubyLLM).to receive(:embed).and_return(fake_response)

        described_class.embed_document(document)
        initial_count = document.embedding_chunks.count

        described_class.embed_document(document)
        expect(document.embedding_chunks.count).to eq(initial_count)
      end
    end

    context "with a Resume" do
      let(:resume) do
        create(:resume, user: user, data: {
          "basics" => { "name" => "John Doe", "headline" => "Software Engineer", "summary" => "10 years experience" },
          "sections" => {
            "experience" => {
              "name" => "Experience",
              "items" => [
                { "company" => "Acme Corp", "position" => "Lead Dev", "summary" => "Led a team of 5 engineers" }
              ]
            }
          }
        })
      end

      it "extracts text from resume data and creates chunks" do
        fake_vectors = [Array.new(dimensions) { rand(-1.0..1.0) }]
        fake_response = double("EmbeddingResponse", vectors: fake_vectors)
        allow(RubyLLM).to receive(:embed).and_return(fake_response)

        count = described_class.embed_document(resume)

        expect(count).to be >= 1
        chunk = resume.embedding_chunks.first
        expect(chunk.chunk_text).to include("John Doe")
        expect(chunk.chunk_text).to include("Software Engineer")
      end
    end

    it "returns nil for documents with blank content" do
      document = create(:knowledge_document, user: user, content: "")
      expect(described_class.embed_document(document)).to be_nil
    end
  end

  describe "#remove_embeddings" do
    it "removes all chunks and vectors for a document" do
      document = create(:knowledge_document, user: user, content: "Test content")
      fake_vectors = [Array.new(dimensions) { rand(-1.0..1.0) }]
      fake_response = double("EmbeddingResponse", vectors: fake_vectors)
      allow(RubyLLM).to receive(:embed).and_return(fake_response)

      described_class.embed_document(document)
      expect(document.embedding_chunks.count).to be >= 1

      described_class.new.remove_embeddings(document)
      expect(document.embedding_chunks.count).to eq(0)
    end
  end

  describe "chunking" do
    it "splits long text into chunks with overlap" do
      long_text = "A" * 2500  # Longer than CHUNK_SIZE
      document = create(:knowledge_document, user: user, content: long_text)

      allow(RubyLLM).to receive(:embed) do |texts, **_opts|
        vecs = Array(texts).map { Array.new(dimensions) { rand(-1.0..1.0) } }
        double("EmbeddingResponse", vectors: vecs)
      end

      described_class.embed_document(document)
      expect(document.embedding_chunks.count).to be > 1
    end
  end
end
