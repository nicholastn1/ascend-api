require "rails_helper"

RSpec.describe "Api::V1::Flags", type: :request do
  describe "GET /api/v1/flags" do
    it "returns feature flags without authentication" do
      get "/api/v1/flags"
      expect(response).to have_http_status(:ok)

      body = response.parsed_body
      expect(body).to have_key("disable_signups")
      expect(body).to have_key("disable_email_auth")
      expect(body).to have_key("disable_update_check")
      expect(body).to have_key("disable_image_processing")
    end

    it "reflects environment variable values" do
      ClimateControl.modify(FLAG_DISABLE_SIGNUPS: "true") do
        get "/api/v1/flags"
        expect(response.parsed_body["disable_signups"]).to be true
      end
    end
  end
end
