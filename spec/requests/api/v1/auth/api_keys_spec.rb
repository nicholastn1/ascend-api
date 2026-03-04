require "rails_helper"

RSpec.describe "Api::V1::Auth::ApiKeys", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "POST /api/v1/auth/api-keys" do
    it "creates a new API key" do
      post "/api/v1/auth/api-keys", params: { name: "My Key" }, headers: headers
      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["name"]).to eq("My Key")
      expect(body["key"]).to start_with("ak_")
    end
  end

  describe "GET /api/v1/auth/api-keys" do
    it "lists user's API keys" do
      create(:api_key, user: user, name: "Key 1")
      create(:api_key, user: user, name: "Key 2")

      get "/api/v1/auth/api-keys", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.length).to eq(2)
    end
  end

  describe "DELETE /api/v1/auth/api-keys/:id" do
    it "revokes an API key" do
      key = create(:api_key, user: user)
      delete "/api/v1/auth/api-keys/#{key.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(ApiKey.find_by(id: key.id)).to be_nil
    end
  end

  describe "API key authentication" do
    it "authenticates requests via X-API-Key header" do
      generated = ApiKey.generate_key
      create(:api_key, user: user, key_digest: generated[:digest], key_start: generated[:key_start])

      get "/api/v1/profile", headers: { "X-API-Key" => generated[:raw_key] }
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["id"]).to eq(user.id)
    end
  end
end
