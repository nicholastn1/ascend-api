require "rails_helper"

RSpec.describe "Api::V1::Auth::Registrations", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      { name: "John Doe", email: "john@example.com", username: "johndoe", password: "password123" }
    end

    it "creates a new user" do
      expect { post "/api/v1/auth/register", params: valid_params }.to change(User, :count).by(1)
      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["email"]).to eq("john@example.com")
      expect(body["username"]).to eq("johndoe")
    end

    it "creates a session" do
      expect { post "/api/v1/auth/register", params: valid_params }.to change(Session, :count).by(1)
    end

    it "sets session cookie" do
      post "/api/v1/auth/register", params: valid_params
      expect(response.cookies["session_token"]).to be_present
    end

    it "returns errors for invalid params" do
      post "/api/v1/auth/register", params: { name: "", email: "" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate email" do
      create(:user, email: "john@example.com")
      post "/api/v1/auth/register", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/auth/account" do
    let(:user) { create(:user) }

    it "deletes the user account" do
      headers = auth_headers(user)
      expect { delete "/api/v1/auth/account", headers: headers }.to change(User, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "requires authentication" do
      delete "/api/v1/auth/account"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
