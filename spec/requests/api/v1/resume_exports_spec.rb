require "rails_helper"

RSpec.describe "Api::V1::ResumeExports", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:resume) { create(:resume, user: user, data: resume_data) }
  let(:resume_data) do
    {
      basics: { name: "John Doe" },
      metadata: {
        template: "rhyhorn",
        page: { format: "a4", locale: "en-US", marginX: 32, marginY: 32 }
      }
    }
  end

  describe "GET /api/v1/resumes/:id/pdf" do
    it "returns 401 when not authenticated" do
      get "/api/v1/resumes/#{resume.id}/pdf"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for non-existent resume" do
      get "/api/v1/resumes/nonexistent/pdf", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 503 when PRINTER_ENDPOINT is not configured" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PRINTER_ENDPOINT").and_return(nil)

      get "/api/v1/resumes/#{resume.id}/pdf", headers: headers
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body["error"]).to include("PRINTER_ENDPOINT")
    end
  end

  describe "GET /api/v1/resumes/:id/screenshot" do
    it "returns 401 when not authenticated" do
      get "/api/v1/resumes/#{resume.id}/screenshot"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for non-existent resume" do
      get "/api/v1/resumes/nonexistent/screenshot", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 503 when PRINTER_ENDPOINT is not configured" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PRINTER_ENDPOINT").and_return(nil)

      get "/api/v1/resumes/#{resume.id}/screenshot", headers: headers
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body["error"]).to include("PRINTER_ENDPOINT")
    end
  end
end
