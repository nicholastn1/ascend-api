require "rails_helper"

RSpec.describe "Api::V1::Applications", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/applications" do
    it "lists user's applications" do
      create_list(:job_application, 3, user: user)
      create(:job_application) # another user's

      get "/api/v1/applications", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end

    it "filters by status" do
      create(:job_application, user: user, current_status: "applied")
      create(:job_application, user: user, current_status: "interview")

      get "/api/v1/applications", params: { status: "interview" }, headers: headers
      expect(response.parsed_body.size).to eq(1)
      expect(response.parsed_body.first["current_status"]).to eq("interview")
    end

    it "filters by company name" do
      create(:job_application, user: user, company_name: "Acme Corp")
      create(:job_application, user: user, company_name: "Globex Inc")

      get "/api/v1/applications", params: { company: "Acme" }, headers: headers
      expect(response.parsed_body.size).to eq(1)
    end

    it "returns 401 when not authenticated" do
      get "/api/v1/applications"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/applications/kanban" do
    it "returns applications grouped by status" do
      create(:job_application, user: user, current_status: "applied")
      create(:job_application, user: user, current_status: "interview")
      create(:job_application, user: user, current_status: "interview")

      get "/api/v1/applications/kanban", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["applied"].size).to eq(1)
      expect(body["interview"].size).to eq(2)
      expect(body["offer"].size).to eq(0)
    end
  end

  describe "POST /api/v1/applications" do
    let(:valid_params) do
      {
        company_name: "Acme Corp",
        job_title: "Software Engineer",
        job_url: "https://acme.com/jobs/123",
        notes: "Applied via website",
        application_date: "2026-03-01"
      }
    end

    it "creates an application with initial history" do
      post "/api/v1/applications", params: valid_params, headers: headers
      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["company_name"]).to eq("Acme Corp")
      expect(body["current_status"]).to eq("applied")

      app = JobApplication.last
      expect(app.histories.count).to eq(1)
      expect(app.histories.first.to_status).to eq("applied")
    end

    it "returns error for missing required fields" do
      post "/api/v1/applications", params: { notes: "test" }, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/applications/:id" do
    it "returns application with contacts and history" do
      app = create(:job_application, user: user)
      create(:job_application_contact, application: app, name: "John Recruiter")
      app.histories.create!(to_status: "applied", changed_at: 2.days.ago)
      app.histories.create!(from_status: "applied", to_status: "screening", changed_at: 1.day.ago)

      get "/api/v1/applications/#{app.id}", headers: headers
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["contacts"].size).to eq(1)
      expect(body["contacts"].first["name"]).to eq("John Recruiter")
      expect(body["history"].size).to eq(2)
    end

    it "returns 404 for another user's application" do
      other_app = create(:job_application)
      get "/api/v1/applications/#{other_app.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/v1/applications/:id" do
    it "updates application fields" do
      app = create(:job_application, user: user, company_name: "Old Name")

      put "/api/v1/applications/#{app.id}",
        params: { company_name: "New Name" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["company_name"]).to eq("New Name")
    end
  end

  describe "POST /api/v1/applications/:id/move" do
    it "moves application to new status and records history" do
      app = create(:job_application, user: user, current_status: "applied")

      post "/api/v1/applications/#{app.id}/move",
        params: { status: "screening" },
        headers: headers

      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body["current_status"]).to eq("screening")
      expect(body["history"].first["to_status"]).to eq("screening")
      expect(body["history"].first["from_status"]).to eq("applied")
    end

    it "returns error for invalid status" do
      app = create(:job_application, user: user)

      post "/api/v1/applications/#{app.id}/move",
        params: { status: "invalid" },
        headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/applications/:id" do
    it "deletes application and related records" do
      app = create(:job_application, user: user)
      create(:job_application_contact, application: app)
      app.histories.create!(to_status: "applied", changed_at: Time.current)

      expect {
        delete "/api/v1/applications/#{app.id}", headers: headers
      }.to change(JobApplication, :count).by(-1)
        .and change(JobApplicationContact, :count).by(-1)
        .and change(JobApplicationHistory, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
