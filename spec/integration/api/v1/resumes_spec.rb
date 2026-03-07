require "swagger_helper"

RSpec.describe "Resumes API", type: :request do
  let(:user) { create(:user) }
  let(:session_record) { create(:session, user: user) }
  let(:Authorization) { "Bearer #{session_record.token}" }

  # ── Resumes CRUD ──────────────────────────────────────────────────────

  path "/api/v1/resumes" do
    get "List resumes" do
      tags "Resumes"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :tag, in: :query, type: :string, required: false, description: "Filter by tag"

      response "200", "resumes listed" do
        before { create_list(:resume, 3, user: user) }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        run_test!
      end
    end

    post "Create a resume" do
      tags "Resumes"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          slug: { type: :string },
          is_public: { type: :boolean },
          tags: { type: :array, items: { type: :string } },
          data: { type: :object }
        },
        required: %w[name]
      }

      response "201", "resume created" do
        let(:body) { { name: "My Resume", slug: "my-resume", data: { basics: { name: "Test" } } } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:body) { { name: "My Resume" } }
        run_test!
      end
    end
  end

  path "/api/v1/resumes/{id}" do
    let(:resume) { create(:resume, user: user) }

    get "Get a resume" do
      tags "Resumes"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "resume found" do
        let(:id) { resume.id }
        run_test!
      end

      response "404", "resume not found" do
        let(:id) { "nonexistent" }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:id) { resume.id }
        run_test!
      end
    end

    put "Update a resume" do
      tags "Resumes"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          slug: { type: :string },
          is_public: { type: :boolean },
          tags: { type: :array, items: { type: :string } },
          data: { type: :object }
        }
      }

      response "200", "resume updated" do
        let(:id) { resume.id }
        let(:body) { { name: "Updated Resume", data: { basics: { name: "Test" } } } }
        run_test!
      end

      response "403", "resume is locked" do
        let(:locked_resume) { create(:resume, :locked, user: user) }
        let(:id) { locked_resume.id }
        let(:body) { { name: "Should Fail" } }
        run_test!
      end
    end

    delete "Delete a resume" do
      tags "Resumes"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "resume deleted" do
        let(:id) { resume.id }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:id) { resume.id }
        run_test!
      end
    end
  end

  # ── Patch Data ─────────────────────────────────────────────────────────

  path "/api/v1/resumes/{id}/patch_data" do
    let(:resume) { create(:resume, user: user) }

    patch "Patch resume data with JSON Patch operations" do
      tags "Resumes"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          operations: {
            type: :array,
            items: {
              type: :object,
              properties: {
                op: { type: :string },
                path: { type: :string },
                value: {}
              }
            }
          }
        },
        required: %w[operations]
      }

      response "200", "resume data patched" do
        let(:id) { resume.id }
        let(:body) { { operations: [ { "op" => "replace", "path" => "/basics/name", "value" => "New Name" } ] } }
        run_test!
      end

      response "403", "resume is locked" do
        let(:locked_resume) { create(:resume, :locked, user: user) }
        let(:id) { locked_resume.id }
        let(:body) { { operations: [ { "op" => "replace", "path" => "/basics/name", "value" => "New Name" } ] } }
        run_test!
      end
    end
  end

  # ── Duplicate ──────────────────────────────────────────────────────────

  path "/api/v1/resumes/{id}/duplicate" do
    let(:resume) { create(:resume, user: user) }

    post "Duplicate a resume" do
      tags "Resumes"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "201", "resume duplicated" do
        let(:id) { resume.id }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:id) { resume.id }
        run_test!
      end
    end
  end

  # ── Lock ───────────────────────────────────────────────────────────────

  path "/api/v1/resumes/{id}/lock" do
    let(:resume) { create(:resume, user: user) }

    post "Toggle resume lock" do
      tags "Resumes"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "lock toggled" do
        let(:id) { resume.id }
        run_test!
      end
    end
  end

  # ── Password ───────────────────────────────────────────────────────────

  path "/api/v1/resumes/{id}/password" do
    let(:resume) { create(:resume, user: user) }

    put "Set resume password" do
      tags "Resume Sharing"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          password: { type: :string }
        },
        required: %w[password]
      }

      response "200", "password set" do
        let(:id) { resume.id }
        let(:body) { { password: "secret123" } }
        run_test!
      end

      response "422", "password missing" do
        let(:id) { resume.id }
        let(:body) { { password: "" } }
        run_test!
      end
    end

    delete "Remove resume password" do
      tags "Resume Sharing"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "password removed" do
        let(:password_resume) { create(:resume, :with_password, user: user) }
        let(:id) { password_resume.id }
        run_test!
      end
    end
  end

  # ── Tags ───────────────────────────────────────────────────────────────

  path "/api/v1/resumes/tags" do
    get "List all unique tags" do
      tags "Resumes"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "tags listed" do
        before { create(:resume, user: user, tags: %w[engineering design]) }
        run_test!
      end
    end
  end

  # ── Import ─────────────────────────────────────────────────────────────

  path "/api/v1/resumes/import" do
    post "Import a resume" do
      tags "Resumes"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          data: { type: :object }
        }
      }

      response "201", "resume imported" do
        let(:body) { { name: "Imported Resume", data: { basics: { name: "Test" } } } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:body) { { name: "Imported Resume", data: { basics: { name: "Test" } } } }
        run_test!
      end
    end
  end

  # ── Public Resume ──────────────────────────────────────────────────────

  path "/api/v1/resumes/public/{username}/{slug}" do
    let(:public_user) { create(:user) }
    let(:public_resume) { create(:resume, :public, user: public_user) }

    get "View a public resume" do
      tags "Resume Sharing"
      produces "application/json"
      parameter name: :username, in: :path, type: :string, required: true
      parameter name: :slug, in: :path, type: :string, required: true

      response "200", "public resume returned" do
        let(:username) { public_user.username }
        let(:slug) { public_resume.slug }
        run_test!
      end

      response "404", "resume not found" do
        let(:username) { "nonexistent" }
        let(:slug) { "nonexistent" }
        run_test!
      end
    end
  end

  path "/api/v1/resumes/public/{username}/{slug}/verify" do
    let(:public_user) { create(:user) }
    let(:password_resume) { create(:resume, :public, :with_password, user: public_user) }

    post "Verify password for a public resume" do
      tags "Resume Sharing"
      consumes "application/json"
      produces "application/json"
      parameter name: :username, in: :path, type: :string, required: true
      parameter name: :slug, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          password: { type: :string }
        },
        required: %w[password]
      }

      response "200", "password verified" do
        let(:username) { public_user.username }
        let(:slug) { password_resume.slug }
        let(:body) { { password: "sharepass123" } }
        run_test!
      end

      response "401", "invalid password" do
        let(:username) { public_user.username }
        let(:slug) { password_resume.slug }
        let(:body) { { password: "wrongpassword" } }
        run_test!
      end
    end
  end

  # ── Statistics ─────────────────────────────────────────────────────────

  path "/api/v1/resumes/{resume_id}/statistics" do
    let(:resume) { create(:resume, user: user) }

    get "Get resume statistics" do
      tags "Resume Statistics"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :resume_id, in: :path, type: :string, required: true

      response "200", "statistics returned" do
        let(:resume_id) { resume.id }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:resume_id) { resume.id }
        run_test!
      end
    end
  end

  # ── Export (PDF / Screenshot) ──────────────────────────────────────────

  path "/api/v1/resumes/{id}/pdf" do
    let(:resume) { create(:resume, user: user) }

    get "Generate PDF of a resume" do
      tags "Resume Export"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "PDF generated" do
        before { skip "Requires Browserless" }
        let(:id) { resume.id }
        run_test!
      end
    end
  end

  path "/api/v1/resumes/{id}/screenshot" do
    let(:resume) { create(:resume, user: user) }

    get "Generate screenshot of a resume" do
      tags "Resume Export"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "screenshot generated" do
        before { skip "Requires Browserless" }
        let(:id) { resume.id }
        run_test!
      end
    end
  end
end
