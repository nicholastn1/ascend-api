require "rails_helper"

RSpec.describe "Api::V1::Storage", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "POST /api/v1/storage/upload" do
    let(:file) { fixture_file_upload("test_image.png", "image/png") }

    around do |example|
      ClimateControl.modify(FLAG_DISABLE_IMAGE_PROCESSING: "true") do
        example.run
      end
    end

    it "uploads a file and returns url and path" do
      post "/api/v1/storage/upload", params: { file: file }, headers: headers
      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["url"]).to be_present
      expect(body["path"]).to include("uploads/#{user.id}/pictures/")
      expect(body["content_type"]).to eq("image/png")
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/storage/upload", params: { file: file }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns error when no file provided" do
      post "/api/v1/storage/upload", params: {}, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to include("No file")
    end

    it "uploads with custom type and resume_id" do
      resume = create(:resume, user: user)
      post "/api/v1/storage/upload",
        params: { file: file, type: "screenshot", resume_id: resume.id },
        headers: headers

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["path"]).to include("screenshots/#{resume.id}")
    end
  end

  describe "DELETE /api/v1/storage/files" do
    it "deletes a file owned by the user" do
      # Create a blob first
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test"),
        filename: "test.txt",
        content_type: "text/plain",
        key: "uploads/#{user.id}/pictures/123.txt"
      )

      delete "/api/v1/storage/files",
        params: { path: "uploads/#{user.id}/pictures/123.txt" },
        headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["deleted"]).to be true
      expect(ActiveStorage::Blob.find_by(key: blob.key)).to be_nil
    end

    it "returns 404 for files owned by another user" do
      other_user = create(:user)
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("test"),
        filename: "test.txt",
        content_type: "text/plain",
        key: "uploads/#{other_user.id}/pictures/123.txt"
      )

      delete "/api/v1/storage/files",
        params: { path: "uploads/#{other_user.id}/pictures/123.txt" },
        headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/storage/files", params: { path: "uploads/test/file.txt" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
