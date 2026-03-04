require "rails_helper"

RSpec.describe "Api::V1::Ai", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "POST /api/v1/ai/test-connection" do
    it "returns 401 when not authenticated" do
      post "/api/v1/ai/test-connection"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns connection test result" do
      allow_any_instance_of(Ai::TestConnection).to receive(:call).and_return(
        { success: true, model: "openrouter/auto", response: "OK" }
      )

      post "/api/v1/ai/test-connection", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["success"]).to be true
    end
  end

  describe "POST /api/v1/ai/parse-pdf" do
    it "returns 401 when not authenticated" do
      post "/api/v1/ai/parse-pdf"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns error when no file provided" do
      post "/api/v1/ai/parse-pdf", params: {}, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to include("No file")
    end
  end

  describe "POST /api/v1/ai/parse-docx" do
    it "returns 401 when not authenticated" do
      post "/api/v1/ai/parse-docx"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns error when no file provided" do
      post "/api/v1/ai/parse-docx", params: {}, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to include("No file")
    end
  end
end
