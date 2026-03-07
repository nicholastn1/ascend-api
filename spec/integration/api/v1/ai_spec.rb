require "swagger_helper"

RSpec.describe "AI Services API", type: :request do
  let(:user) { create(:user) }
  let(:session_record) { create(:session, user: user) }
  let(:Authorization) { "Bearer #{session_record.token}" }

  # ── Test Connection ────────────────────────────────────────────────────────

  path "/api/v1/ai/test-connection" do
    post "Test AI provider connection" do
      tags "AI Services"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          model_id: { type: :string }
        }
      }

      response "200", "connection test result" do
        let(:body) { { model_id: "openrouter/auto" } }

        before { skip "Requires AI provider" }
        run_test!
      end
    end
  end

  # ── Parse PDF ──────────────────────────────────────────────────────────────

  path "/api/v1/ai/parse-pdf" do
    post "Parse a PDF file with AI" do
      tags "AI Services"
      consumes "multipart/form-data"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :file, in: :formData, type: :file, description: "PDF file to parse"
      parameter name: :model_id, in: :formData, type: :string, required: false, description: "AI model to use"

      response "200", "PDF parsed successfully" do
        before { skip "Requires AI provider" }
        run_test!
      end
    end
  end

  # ── Parse DOCX ─────────────────────────────────────────────────────────────

  path "/api/v1/ai/parse-docx" do
    post "Parse a DOCX file with AI" do
      tags "AI Services"
      consumes "multipart/form-data"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :file, in: :formData, type: :file, description: "DOCX file to parse"
      parameter name: :model_id, in: :formData, type: :string, required: false, description: "AI model to use"

      response "200", "DOCX parsed successfully" do
        before { skip "Requires AI provider" }
        run_test!
      end
    end
  end
end
