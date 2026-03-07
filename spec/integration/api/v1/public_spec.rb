require "swagger_helper"

RSpec.describe "Public & Utility API", type: :request do
  # ── Health ─────────────────────────────────────────────────────────────────

  path "/api/v1/health" do
    get "Health check" do
      tags "Health"
      produces "application/json"

      response "200", "service is healthy" do
        run_test!
      end
    end
  end

  # ── Feature Flags ──────────────────────────────────────────────────────────

  path "/api/v1/flags" do
    get "List feature flags" do
      tags "Feature Flags"
      produces "application/json"

      response "200", "flags returned" do
        run_test!
      end
    end
  end

  # ── Statistics ─────────────────────────────────────────────────────────────

  path "/api/v1/statistics/users" do
    get "Get total user count" do
      tags "Statistics"
      produces "application/json"

      response "200", "user count returned" do
        run_test!
      end
    end
  end

  path "/api/v1/statistics/resumes" do
    get "Get total resume count" do
      tags "Statistics"
      produces "application/json"

      response "200", "resume count returned" do
        run_test!
      end
    end
  end

  # ── Prompts ────────────────────────────────────────────────────────────────

  context "with authenticated user" do
    let(:user) { create(:user) }
    let(:session_record) { create(:session, user: user) }
    let(:Authorization) { "Bearer #{session_record.token}" }

    path "/api/v1/prompts" do
      get "List all prompts" do
        tags "Prompts"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        response "200", "prompts listed" do
          before do
            AiPrompt.create!(slug: "improve-writing", title: "Improve Writing", content: "You are a writing assistant.")
          end

          run_test!
        end
      end
    end

    path "/api/v1/prompts/{slug}" do
      parameter name: :slug, in: :path, type: :string, description: "Prompt slug"

      get "Show a prompt" do
        tags "Prompts"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        response "200", "prompt found" do
          let(:slug) { "improve-writing" }

          before do
            AiPrompt.create!(slug: "improve-writing", title: "Improve Writing", content: "You are a writing assistant.")
          end

          run_test!
        end
      end

      put "Update a prompt (admin only)" do
        tags "Prompts"
        consumes "application/json"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        parameter name: :body, in: :body, schema: {
          type: :object,
          properties: {
            title: { type: :string },
            description: { type: :string },
            content: { type: :string }
          }
        }

        response "200", "prompt updated" do
          let(:slug) { "improve-writing" }
          let(:body) { { content: "Updated prompt content." } }

          before do
            AiPrompt.create!(slug: "improve-writing", title: "Improve Writing", content: "You are a writing assistant.")
            ClimateControl.modify(ADMIN_EMAILS: user.email) do
              # Need to set this before the request runs
            end
          end

          around do |example|
            ClimateControl.modify(ADMIN_EMAILS: user.email) do
              example.run
            end
          end

          run_test!
        end
      end
    end
  end

  # ── Storage ────────────────────────────────────────────────────────────────

  context "with authenticated user for storage" do
    let(:user) { create(:user) }
    let(:session_record) { create(:session, user: user) }
    let(:Authorization) { "Bearer #{session_record.token}" }

    path "/api/v1/storage/upload" do
      post "Upload a file" do
        tags "Storage"
        consumes "multipart/form-data"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        parameter name: :file, in: :formData, type: :file, description: "File to upload"
        parameter name: :type, in: :formData, type: :string, required: false, description: "Upload type (picture, screenshot, pdf)"
        parameter name: :resume_id, in: :formData, type: :string, required: false, description: "Associated resume ID"

        response "201", "file uploaded" do
          before { skip "Requires file fixture and Active Storage setup" }
          run_test!
        end
      end
    end

    path "/api/v1/storage/files" do
      delete "Delete a file" do
        tags "Storage"
        consumes "application/json"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        parameter name: :body, in: :body, schema: {
          type: :object,
          properties: {
            path: { type: :string }
          },
          required: %w[path]
        }

        response "200", "file deleted" do
          let(:body) { { path: "uploads/#{user.id}/pictures/test.webp" } }

          before { skip "Requires Active Storage blob setup" }
          run_test!
        end
      end
    end
  end

  # ── Profile ────────────────────────────────────────────────────────────────

  context "with authenticated user for profile" do
    let(:user) { create(:user) }
    let(:session_record) { create(:session, user: user) }
    let(:Authorization) { "Bearer #{session_record.token}" }

    path "/api/v1/profile" do
      get "Get current user profile" do
        tags "Profile"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        response "200", "profile returned" do
          run_test!
        end
      end

      put "Update current user profile" do
        tags "Profile"
        consumes "application/json"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        parameter name: :body, in: :body, schema: {
          type: :object,
          properties: {
            name: { type: :string },
            username: { type: :string },
            display_username: { type: :string },
            image: { type: :string }
          }
        }

        response "200", "profile updated" do
          let(:body) { { name: "New Name" } }
          run_test!
        end
      end
    end

    path "/api/v1/profile/password" do
      put "Update password" do
        tags "Profile"
        consumes "application/json"
        produces "application/json"
        security [ { bearer_auth: [] } ]

        parameter name: :body, in: :body, schema: {
          type: :object,
          properties: {
            current_password: { type: :string },
            new_password: { type: :string }
          },
          required: %w[current_password new_password]
        }

        response "200", "password updated" do
          let(:body) { { current_password: "password123", new_password: "newpassword456" } }
          run_test!
        end
      end
    end
  end
end
