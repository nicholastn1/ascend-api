require "rails_helper"

RSpec.describe "Api::V1::Chat::RateLimit", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/chat/rate-limit" do
    it "returns rate limit info" do
      get "/api/v1/chat/rate-limit", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["used"]).to eq(0)
      expect(body["limit"]).to be_a(Integer)
      expect(body["remaining"]).to be_a(Integer)
      expect(body["resets_at"]).to be_present
    end

    it "returns 401 when not authenticated" do
      get "/api/v1/chat/rate-limit"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
