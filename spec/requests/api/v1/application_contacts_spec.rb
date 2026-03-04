require "rails_helper"

RSpec.describe "Api::V1::ApplicationContacts", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:application) { create(:job_application, user: user) }

  describe "GET /api/v1/applications/:application_id/contacts" do
    it "lists contacts for an application" do
      create_list(:job_application_contact, 2, application: application)

      get "/api/v1/applications/#{application.id}/contacts", headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end
  end

  describe "POST /api/v1/applications/:application_id/contacts" do
    it "creates a contact" do
      post "/api/v1/applications/#{application.id}/contacts",
        params: { name: "Jane Doe", role: "Recruiter", email: "jane@example.com" },
        headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["name"]).to eq("Jane Doe")
      expect(response.parsed_body["role"]).to eq("Recruiter")
    end

    it "returns error for missing name" do
      post "/api/v1/applications/#{application.id}/contacts",
        params: { role: "Recruiter" },
        headers: headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PUT /api/v1/applications/:application_id/contacts/:id" do
    it "updates a contact" do
      contact = create(:job_application_contact, application: application, name: "Old Name")

      put "/api/v1/applications/#{application.id}/contacts/#{contact.id}",
        params: { name: "New Name" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("New Name")
    end
  end

  describe "DELETE /api/v1/applications/:application_id/contacts/:id" do
    it "deletes a contact" do
      contact = create(:job_application_contact, application: application)

      expect {
        delete "/api/v1/applications/#{application.id}/contacts/#{contact.id}", headers: headers
      }.to change(JobApplicationContact, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
