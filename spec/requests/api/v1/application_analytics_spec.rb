require "rails_helper"

RSpec.describe "Api::V1::ApplicationAnalytics", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/applications/analytics/overview" do
    it "returns counts by status" do
      create_list(:job_application, 3, user: user, current_status: "applied")
      create_list(:job_application, 2, user: user, current_status: "interview")
      create(:job_application, user: user, current_status: "offer")

      get "/api/v1/applications/analytics/overview", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["total"]).to eq(6)
      expect(body["by_status"]["applied"]).to eq(3)
      expect(body["by_status"]["interview"]).to eq(2)
      expect(body["by_status"]["offer"]).to eq(1)
      expect(body["by_status"]["rejected"]).to eq(0)
    end
  end

  describe "GET /api/v1/applications/analytics/timeline" do
    it "returns applications over time" do
      create(:job_application, user: user, created_at: 1.month.ago)
      create(:job_application, user: user, created_at: 1.month.ago)
      create(:job_application, user: user, created_at: Time.current)

      get "/api/v1/applications/analytics/timeline", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to be >= 1
    end
  end

  describe "GET /api/v1/applications/analytics/funnel" do
    it "returns conversion funnel" do
      create_list(:job_application, 5, user: user, current_status: "applied")
      create_list(:job_application, 3, user: user, current_status: "interview")
      create(:job_application, user: user, current_status: "offer")

      get "/api/v1/applications/analytics/funnel", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body.first["status"]).to eq("applied")
      expect(body.first["rate"]).to eq(100.0)
    end

    it "returns empty array when no applications" do
      get "/api/v1/applications/analytics/funnel", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /api/v1/applications/analytics/avg-time" do
    it "returns average days per stage" do
      get "/api/v1/applications/analytics/avg-time", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body.size).to eq(JobApplication::STATUSES.size)
      expect(body.first).to have_key("status")
      expect(body.first).to have_key("avg_days")
      expect(body.first).to have_key("sample_size")
    end
  end
end
