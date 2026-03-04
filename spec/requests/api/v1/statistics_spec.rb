require "rails_helper"

RSpec.describe "Api::V1::Statistics", type: :request do
  describe "GET /api/v1/statistics/users" do
    it "returns user count without authentication" do
      create_list(:user, 3)

      get "/api/v1/statistics/users"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["count"]).to eq(3)
    end
  end

  describe "GET /api/v1/statistics/resumes" do
    it "returns resume count without authentication" do
      user = create(:user)
      create_list(:resume, 2, user: user)

      get "/api/v1/statistics/resumes"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["count"]).to eq(2)
    end
  end
end
