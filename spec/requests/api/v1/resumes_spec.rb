require "rails_helper"

RSpec.describe "Api::V1::Resumes", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/resumes" do
    it "lists user's resumes" do
      create_list(:resume, 3, user: user)
      create(:resume) # another user's resume

      get "/api/v1/resumes", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body.length).to eq(3)
      expect(body.first).not_to have_key("data") # summary only
    end
  end

  describe "POST /api/v1/resumes" do
    it "creates a resume" do
      params = { name: "My Resume", slug: "my-resume", data: { basics: { name: "John" } } }
      post "/api/v1/resumes", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["name"]).to eq("My Resume")
      expect(body["slug"]).to eq("my-resume")
      expect(body["data"]["basics"]["name"]).to eq("John")
      expect(body["statistics"]["views"]).to eq(0)
    end

    it "auto-generates slug from name" do
      params = { name: "My Awesome Resume", data: { basics: {} } }
      post "/api/v1/resumes", params: params, headers: headers, as: :json
      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["slug"]).to eq("my-awesome-resume")
    end
  end

  describe "GET /api/v1/resumes/:id" do
    it "returns resume with full data" do
      resume = create(:resume, user: user)
      get "/api/v1/resumes/#{resume.id}", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["id"]).to eq(resume.id)
      expect(body).to have_key("data")
    end
  end

  describe "PATCH /api/v1/resumes/:id/patch_data" do
    it "applies JSON Patch operations" do
      resume = create(:resume, user: user, data: { "basics" => { "name" => "Old Name" } })
      operations = [ { "op" => "replace", "path" => "/basics/name", "value" => "New Name" } ]

      patch "/api/v1/resumes/#{resume.id}/patch_data", params: { operations: operations },
        headers: headers, as: :json
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["data"]["basics"]["name"]).to eq("New Name")
    end

    it "rejects patch on locked resume" do
      resume = create(:resume, :locked, user: user)
      operations = [ { "op" => "replace", "path" => "/basics/name", "value" => "New" } ]

      patch "/api/v1/resumes/#{resume.id}/patch_data", params: { operations: operations },
        headers: headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/resumes/:id/duplicate" do
    it "duplicates a resume" do
      resume = create(:resume, user: user, name: "Original")
      post "/api/v1/resumes/#{resume.id}/duplicate", headers: headers
      expect(response).to have_http_status(:created)

      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Original (Copy)")
      expect(user.resumes.count).to eq(2)
    end
  end

  describe "POST /api/v1/resumes/:id/lock" do
    it "toggles lock" do
      resume = create(:resume, user: user, is_locked: false)
      post "/api/v1/resumes/#{resume.id}/lock", headers: headers
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["is_locked"]).to be(true)
    end
  end

  describe "PUT /api/v1/resumes/:id/password" do
    it "sets a share password" do
      resume = create(:resume, user: user)
      put "/api/v1/resumes/#{resume.id}/password", params: { password: "secret" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(resume.reload.password_protected?).to be(true)
    end
  end

  describe "DELETE /api/v1/resumes/:id/password" do
    it "removes share password" do
      resume = create(:resume, :with_password, user: user)
      delete "/api/v1/resumes/#{resume.id}/password", headers: headers
      expect(response).to have_http_status(:ok)
      expect(resume.reload.password_protected?).to be(false)
    end
  end

  describe "DELETE /api/v1/resumes/:id" do
    it "deletes a resume" do
      resume = create(:resume, user: user)
      expect { delete "/api/v1/resumes/#{resume.id}", headers: headers }.to change(Resume, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/resumes/public/:username/:slug" do
    it "returns public resume" do
      resume = create(:resume, :public, user: user)
      get "/api/v1/resumes/public/#{user.username}/#{resume.slug}"
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["data"]).to be_present
    end

    it "returns requires_password for password-protected resume" do
      resume = create(:resume, :public, :with_password, user: user)
      get "/api/v1/resumes/public/#{user.username}/#{resume.slug}"
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["requires_password"]).to be(true)
    end

    it "returns 404 for non-public resume" do
      resume = create(:resume, user: user, is_public: false)
      get "/api/v1/resumes/public/#{user.username}/#{resume.slug}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/resumes/public/:username/:slug/verify" do
    it "grants access with correct password" do
      resume = create(:resume, :public, :with_password, user: user)
      post "/api/v1/resumes/public/#{user.username}/#{resume.slug}/verify",
        params: { password: "sharepass123" }
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["data"]).to be_present
    end

    it "rejects wrong password" do
      resume = create(:resume, :public, :with_password, user: user)
      post "/api/v1/resumes/public/#{user.username}/#{resume.slug}/verify",
        params: { password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
