require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  describe "POST /api/v1/auth/login" do
    let(:user) { create(:user, email: "test@example.com", password: "password123") }

    it "authenticates with valid credentials" do
      post "/api/v1/auth/login", params: { email: user.email, password: "password123" }
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["email"]).to eq(user.email)
    end

    it "sets session cookie" do
      post "/api/v1/auth/login", params: { email: user.email, password: "password123" }
      expect(response.cookies["session_token"]).to be_present
    end

    it "rejects invalid password" do
      post "/api/v1/auth/login", params: { email: user.email, password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects unknown email" do
      post "/api/v1/auth/login", params: { email: "unknown@example.com", password: "pass" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/session" do
    let(:user) { create(:user) }

    it "returns current user" do
      get "/api/v1/auth/session", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["id"]).to eq(user.id)
    end

    it "requires authentication" do
      get "/api/v1/auth/session"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:user) { create(:user) }

    it "destroys the session" do
      headers = auth_headers(user)
      expect { delete "/api/v1/auth/logout", headers: headers }.to change(Session, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end
end
