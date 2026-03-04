require "rails_helper"

RSpec.describe "Api::V1::Prompts", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let!(:prompt) do
    AiPrompt.create!(
      slug: "test-prompt",
      title: "Test Prompt",
      description: "A test prompt",
      content: "You are a helpful assistant."
    )
  end

  describe "GET /api/v1/prompts" do
    it "lists all prompts" do
      get "/api/v1/prompts", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to be >= 1
      expect(response.parsed_body.first).to have_key("slug")
    end

    it "returns 401 when not authenticated" do
      get "/api/v1/prompts"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/prompts/:slug" do
    it "returns a prompt by slug" do
      get "/api/v1/prompts/test-prompt", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["slug"]).to eq("test-prompt")
      expect(response.parsed_body["content"]).to eq("You are a helpful assistant.")
    end

    it "returns 404 for non-existent slug" do
      get "/api/v1/prompts/nonexistent", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/prompts/:slug" do
    it "updates a prompt" do
      put "/api/v1/prompts/test-prompt",
        params: { content: "Updated content" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq("Updated content")
      expect(prompt.reload.content).to eq("Updated content")
    end
  end
end
