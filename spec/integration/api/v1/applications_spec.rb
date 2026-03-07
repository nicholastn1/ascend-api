require "swagger_helper"

RSpec.describe "Applications API", type: :request do
  let(:user) { create(:user) }
  let(:session_record) { create(:session, user: user) }
  let(:Authorization) { "Bearer #{session_record.token}" }

  # ── Applications CRUD ─────────────────────────────────────────────────

  path "/api/v1/applications" do
    get "List job applications" do
      tags "Applications"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :status, in: :query, type: :string, required: false, description: "Filter by status"
      parameter name: :company, in: :query, type: :string, required: false, description: "Filter by company name"
      parameter name: :date_from, in: :query, type: :string, required: false, description: "Filter from date"
      parameter name: :date_to, in: :query, type: :string, required: false, description: "Filter to date"
      parameter name: :salary_min, in: :query, type: :number, required: false, description: "Minimum salary"
      parameter name: :salary_max, in: :query, type: :number, required: false, description: "Maximum salary"

      response "200", "applications listed" do
        before { create_list(:job_application, 3, user: user) }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        run_test!
      end
    end

    post "Create a job application" do
      tags "Applications"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          company_name: { type: :string },
          job_title: { type: :string },
          job_url: { type: :string },
          current_status: { type: :string },
          salary_amount: { type: :number },
          salary_currency: { type: :string },
          salary_period: { type: :string },
          notes: { type: :string },
          application_date: { type: :string, format: :date }
        },
        required: %w[company_name job_title]
      }

      response "201", "application created" do
        let(:body) do
          {
            company_name: "Acme Corp",
            job_title: "Software Engineer",
            job_url: "https://acme.com/jobs/1",
            current_status: "applied",
            notes: "Exciting opportunity",
            application_date: Date.current.to_s
          }
        end
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:body) { { company_name: "Acme Corp", job_title: "Software Engineer" } }
        run_test!
      end
    end
  end

  path "/api/v1/applications/kanban" do
    get "Get applications grouped by status (kanban)" do
      tags "Applications"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "kanban board returned" do
        before do
          create(:job_application, user: user, current_status: "applied")
          create(:job_application, user: user, current_status: "interview")
        end
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        run_test!
      end
    end
  end

  path "/api/v1/applications/{id}" do
    let(:application) { create(:job_application, user: user) }

    get "Get a job application" do
      tags "Applications"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "200", "application found" do
        let(:id) { application.id }
        run_test!
      end

      response "404", "application not found" do
        let(:id) { "nonexistent" }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:id) { application.id }
        run_test!
      end
    end

    put "Update a job application" do
      tags "Applications"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          company_name: { type: :string },
          job_title: { type: :string },
          job_url: { type: :string },
          salary_amount: { type: :number },
          salary_currency: { type: :string },
          salary_period: { type: :string },
          notes: { type: :string },
          application_date: { type: :string, format: :date }
        }
      }

      response "200", "application updated" do
        let(:id) { application.id }
        let(:body) { { company_name: "Updated Corp", job_title: "Senior Engineer" } }
        run_test!
      end

      response "404", "application not found" do
        let(:id) { "nonexistent" }
        let(:body) { { company_name: "Updated Corp" } }
        run_test!
      end
    end

    delete "Delete a job application" do
      tags "Applications"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true

      response "204", "application deleted" do
        let(:id) { application.id }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:id) { application.id }
        run_test!
      end
    end
  end

  # ── Move (status transition) ──────────────────────────────────────────

  path "/api/v1/applications/{id}/move" do
    let(:application) { create(:job_application, user: user, current_status: "applied") }

    post "Move application to a new status" do
      tags "Applications"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          status: { type: :string, enum: %w[applied screening interview offer negotiation accepted rejected] }
        },
        required: %w[status]
      }

      response "200", "application moved" do
        let(:id) { application.id }
        let(:body) { { status: "screening" } }
        run_test!
      end

      response "422", "invalid status" do
        let(:id) { application.id }
        let(:body) { { status: "invalid_status" } }
        run_test!
      end
    end
  end

  # ── Contacts ──────────────────────────────────────────────────────────

  path "/api/v1/applications/{application_id}/contacts" do
    let(:application) { create(:job_application, user: user) }

    get "List contacts for an application" do
      tags "Application Contacts"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :application_id, in: :path, type: :string, required: true

      response "200", "contacts listed" do
        let(:application_id) { application.id }
        before { create_list(:job_application_contact, 2, application: application) }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:application_id) { application.id }
        run_test!
      end
    end

    post "Create a contact for an application" do
      tags "Application Contacts"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :application_id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          role: { type: :string },
          email: { type: :string },
          phone: { type: :string },
          linkedin_url: { type: :string }
        },
        required: %w[name]
      }

      response "201", "contact created" do
        let(:application_id) { application.id }
        let(:body) do
          {
            name: "Jane Smith",
            role: "Hiring Manager",
            email: "jane@example.com",
            phone: "+1234567890",
            linkedin_url: "https://linkedin.com/in/janesmith"
          }
        end
        run_test!
      end

      response "422", "validation failed" do
        let(:application_id) { application.id }
        let(:body) { { name: "" } }
        run_test!
      end
    end
  end

  path "/api/v1/applications/{application_id}/contacts/{id}" do
    let(:application) { create(:job_application, user: user) }
    let(:contact) { create(:job_application_contact, application: application) }

    put "Update a contact" do
      tags "Application Contacts"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :application_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          role: { type: :string },
          email: { type: :string },
          phone: { type: :string },
          linkedin_url: { type: :string }
        }
      }

      response "200", "contact updated" do
        let(:application_id) { application.id }
        let(:id) { contact.id }
        let(:body) { { name: "Updated Name", role: "CTO" } }
        run_test!
      end

      response "404", "contact not found" do
        let(:application_id) { application.id }
        let(:id) { "nonexistent" }
        let(:body) { { name: "Updated Name" } }
        run_test!
      end
    end

    delete "Delete a contact" do
      tags "Application Contacts"
      security [ { bearer_auth: [] } ]
      parameter name: :application_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response "204", "contact deleted" do
        let(:application_id) { application.id }
        let(:id) { contact.id }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:application_id) { application.id }
        let(:id) { contact.id }
        run_test!
      end
    end
  end

  # ── History ───────────────────────────────────────────────────────────

  path "/api/v1/applications/{application_id}/history" do
    let(:application) { create(:job_application, user: user) }

    get "List status history for an application" do
      tags "Application History"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :application_id, in: :path, type: :string, required: true

      response "200", "history listed" do
        let(:application_id) { application.id }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        let(:application_id) { application.id }
        run_test!
      end
    end
  end

  # ── Analytics ─────────────────────────────────────────────────────────

  path "/api/v1/applications/analytics/overview" do
    get "Get application analytics overview" do
      tags "Application Analytics"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "overview returned" do
        before { create_list(:job_application, 3, user: user) }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        run_test!
      end
    end
  end

  path "/api/v1/applications/analytics/timeline" do
    get "Get application timeline analytics" do
      tags "Application Analytics"
      produces "application/json"
      security [ { bearer_auth: [] } ]
      parameter name: :period, in: :query, type: :string, required: false, description: "Grouping period (week or month)"
      parameter name: :months, in: :query, type: :integer, required: false, description: "Number of months to look back"

      response "200", "timeline returned" do
        before { create_list(:job_application, 3, user: user) }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        run_test!
      end
    end
  end

  path "/api/v1/applications/analytics/funnel" do
    get "Get application funnel analytics" do
      tags "Application Analytics"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "funnel returned" do
        before do
          create(:job_application, user: user, current_status: "applied")
          create(:job_application, user: user, current_status: "interview")
          create(:job_application, user: user, current_status: "offer")
        end
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        run_test!
      end
    end
  end

  path "/api/v1/applications/analytics/avg-time" do
    get "Get average time per application stage" do
      tags "Application Analytics"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "average times returned" do
        before { create_list(:job_application, 2, user: user) }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "" }
        run_test!
      end
    end
  end
end
