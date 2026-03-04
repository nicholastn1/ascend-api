require "rails_helper"

RSpec.describe "Api::V1::Knowledge", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/knowledge" do
    it "returns 401 when not authenticated" do
      get "/api/v1/knowledge"
      expect(response).to have_http_status(:unauthorized)
    end

    it "lists user's knowledge documents" do
      create(:knowledge_document, user: user, title: "My Notes")
      create(:knowledge_document, user: user, title: "My Sheet")
      # Another user's doc should not appear
      create(:knowledge_document, title: "Other User Doc")

      get "/api/v1/knowledge", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body.length).to eq(2)
      expect(body.map { |d| d["title"] }).to contain_exactly("My Notes", "My Sheet")
    end
  end

  describe "POST /api/v1/knowledge" do
    it "creates a text document" do
      post "/api/v1/knowledge",
        params: { title: "Career Tips", source_type: "text", content: "Always follow up after interviews." },
        headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["title"]).to eq("Career Tips")
      expect(body["source_type"]).to eq("text")
    end

    it "creates a google_sheet document and enqueues ingest job" do
      post "/api/v1/knowledge",
        params: {
          title: "Job Tracker Sheet",
          source_type: "google_sheet",
          source_url: "https://docs.google.com/spreadsheets/d/abc123/edit"
        },
        headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["source_type"]).to eq("google_sheet")
      expect(KnowledgeIngestJob).to have_been_enqueued
    end

    it "returns 422 for invalid params" do
      post "/api/v1/knowledge",
        params: { source_type: "text" },
        headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/knowledge", params: { title: "Test", source_type: "text" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PUT /api/v1/knowledge/:id" do
    let!(:document) { create(:knowledge_document, user: user) }

    it "updates a document" do
      put "/api/v1/knowledge/#{document.id}",
        params: { title: "Updated Title" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("Updated Title")
    end

    it "returns 404 for another user's document" do
      other_doc = create(:knowledge_document)
      put "/api/v1/knowledge/#{other_doc.id}",
        params: { title: "Hacked" },
        headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/knowledge/:id" do
    let!(:document) { create(:knowledge_document, user: user) }

    it "deletes a document" do
      delete "/api/v1/knowledge/#{document.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(KnowledgeDocument.find_by(id: document.id)).to be_nil
    end

    it "returns 404 for another user's document" do
      other_doc = create(:knowledge_document)
      delete "/api/v1/knowledge/#{other_doc.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/knowledge/:id/sync" do
    it "enqueues sync for a google_sheet document" do
      document = create(:knowledge_document, :google_sheet, user: user)
      post "/api/v1/knowledge/#{document.id}/sync", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("Sync started")
      expect(KnowledgeIngestJob).to have_been_enqueued
    end

    it "rejects sync for non-google_sheet documents" do
      document = create(:knowledge_document, user: user, source_type: "text")
      post "/api/v1/knowledge/#{document.id}/sync", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/knowledge/search" do
    it "returns 401 when not authenticated" do
      post "/api/v1/knowledge/search", params: { query: "test" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 422 when query is blank" do
      post "/api/v1/knowledge/search", params: { query: "" }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns search results" do
      # Mock the semantic search to avoid needing real embeddings
      allow(Knowledge::SemanticSearch).to receive(:search).and_return([
        { chunk_text: "Relevant content", distance: 0.1, document_title: "Test Doc", document_type: "KnowledgeDocument" }
      ])

      post "/api/v1/knowledge/search", params: { query: "career advice" }, headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["results"]).to be_an(Array)
      expect(body["results"].first["chunk_text"]).to eq("Relevant content")
    end
  end
end
