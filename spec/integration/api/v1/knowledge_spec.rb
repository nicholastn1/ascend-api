require "swagger_helper"

RSpec.describe "Knowledge Base API", type: :request do
  let(:user) { create(:user) }
  let(:session_record) { create(:session, user: user) }
  let(:Authorization) { "Bearer #{session_record.token}" }

  # ── Index ──────────────────────────────────────────────────────────────────

  path "/api/v1/knowledge" do
    get "List knowledge documents" do
      tags "Knowledge Base"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "documents listed" do
        before { create_list(:knowledge_document, 2, user: user) }
        run_test!
      end
    end

    post "Create a knowledge document" do
      tags "Knowledge Base"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          source_type: { type: :string, enum: %w[text google_sheet file] },
          content: { type: :string },
          source_url: { type: :string }
        },
        required: %w[title source_type]
      }

      response "201", "document created" do
        let(:body) { { title: "My Notes", source_type: "text", content: "Some useful content." } }

        before do
          allow(KnowledgeIngestJob).to receive(:perform_later)
        end

        run_test!
      end
    end
  end

  # ── Show / Update / Delete ─────────────────────────────────────────────────

  path "/api/v1/knowledge/{id}" do
    parameter name: :id, in: :path, type: :string, description: "Knowledge document ID"

    let(:document) { create(:knowledge_document, user: user) }
    let(:id) { document.id }

    put "Update a knowledge document" do
      tags "Knowledge Base"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          content: { type: :string },
          source_url: { type: :string }
        }
      }

      response "200", "document updated" do
        let(:body) { { title: "Updated Title" } }

        before do
          allow(KnowledgeIngestJob).to receive(:perform_later)
        end

        run_test!
      end
    end

    delete "Delete a knowledge document" do
      tags "Knowledge Base"
      security [ { bearer_auth: [] } ]

      response "204", "document deleted" do
        before do
          allow(Knowledge::EmbeddingService).to receive(:remove_embeddings)
        end

        run_test!
      end
    end
  end

  # ── Sync ───────────────────────────────────────────────────────────────────

  path "/api/v1/knowledge/{id}/sync" do
    parameter name: :id, in: :path, type: :string, description: "Knowledge document ID"

    post "Sync a Google Sheet knowledge document" do
      tags "Knowledge Base"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "sync started" do
        let(:document) { create(:knowledge_document, :google_sheet, user: user) }
        let(:id) { document.id }

        before do
          allow(KnowledgeIngestJob).to receive(:perform_later)
        end

        run_test!
      end
    end
  end

  # ── Search ─────────────────────────────────────────────────────────────────

  path "/api/v1/knowledge/search" do
    post "Semantic search across knowledge base" do
      tags "Knowledge Base"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          query: { type: :string },
          limit: { type: :integer }
        },
        required: %w[query]
      }

      response "200", "search results returned" do
        let(:body) { { query: "resume tips", limit: 5 } }

        before do
          allow(Knowledge::SemanticSearch).to receive(:search).and_return([])
        end

        run_test!
      end
    end
  end
end
