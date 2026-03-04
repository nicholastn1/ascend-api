# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_04_004266) do
  create_table "ai_prompts", id: :string, force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_ai_prompts_on_slug", unique: true
  end

  create_table "api_keys", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true
    t.datetime "expires_at"
    t.string "key_digest", null: false
    t.string "key_start"
    t.datetime "last_refill_at"
    t.datetime "last_request_at"
    t.json "metadata"
    t.string "name"
    t.text "permissions"
    t.string "prefix"
    t.boolean "rate_limit_enabled", default: false
    t.integer "rate_limit_max"
    t.integer "rate_limit_time_window"
    t.integer "refill_amount"
    t.integer "refill_interval"
    t.integer "remaining"
    t.integer "request_count", default: 0
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["enabled", "user_id"], name: "index_api_keys_on_enabled_and_user_id"
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "conversations", id: :string, force: :cascade do |t|
    t.string "agent_type", default: "general"
    t.datetime "created_at", null: false
    t.string "model_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["user_id", "updated_at"], name: "index_conversations_on_user_id_and_updated_at"
    t.index ["user_id"], name: "index_conversations_on_user_id"
  end

  create_table "job_application_contacts", id: :string, force: :cascade do |t|
    t.string "application_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "linkedin_url"
    t.string "name", null: false
    t.string "phone"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_job_application_contacts_on_application_id"
  end

  create_table "job_application_histories", id: :string, force: :cascade do |t|
    t.string "application_id", null: false
    t.datetime "changed_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "from_status"
    t.string "to_status", null: false
    t.index ["application_id", "changed_at"], name: "idx_on_application_id_changed_at_e2ee9da387"
  end

  create_table "job_applications", id: :string, force: :cascade do |t|
    t.date "application_date"
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.string "current_status", default: "applied"
    t.string "job_title", null: false
    t.string "job_url"
    t.text "notes"
    t.decimal "salary_amount"
    t.string "salary_currency", default: "USD"
    t.string "salary_period"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["user_id", "company_name"], name: "index_job_applications_on_user_id_and_company_name"
    t.index ["user_id", "created_at"], name: "index_job_applications_on_user_id_and_created_at"
    t.index ["user_id", "current_status"], name: "index_job_applications_on_user_id_and_current_status"
  end

  create_table "knowledge_documents", id: :string, force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "last_synced_at"
    t.json "metadata"
    t.string "source_type", null: false
    t.string "source_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["user_id", "source_type"], name: "index_knowledge_documents_on_user_id_and_source_type"
    t.index ["user_id"], name: "index_knowledge_documents_on_user_id"
  end

  create_table "messages", id: :string, force: :cascade do |t|
    t.text "content"
    t.text "content_raw"
    t.string "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.json "metadata"
    t.integer "output_tokens"
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "oauth_accounts", id: :string, force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "id_token"
    t.string "provider", null: false
    t.string "provider_uid", null: false
    t.string "refresh_token"
    t.string "scope"
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["provider", "provider_uid"], name: "index_oauth_accounts_on_provider_and_provider_uid", unique: true
    t.index ["user_id"], name: "index_oauth_accounts_on_user_id"
  end

  create_table "passkeys", id: :string, force: :cascade do |t|
    t.string "aaguid"
    t.boolean "backed_up", default: false
    t.integer "counter", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "credential_id", null: false
    t.string "device_type", null: false
    t.string "name"
    t.text "public_key", null: false
    t.text "transports"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["credential_id"], name: "index_passkeys_on_credential_id", unique: true
    t.index ["user_id"], name: "index_passkeys_on_user_id"
  end

  create_table "resume_statistics", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "downloads", default: 0
    t.datetime "last_downloaded_at"
    t.datetime "last_viewed_at"
    t.string "resume_id", null: false
    t.datetime "updated_at", null: false
    t.integer "views", default: 0
    t.index ["resume_id"], name: "index_resume_statistics_on_resume_id", unique: true
  end

  create_table "resumes", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data", null: false
    t.boolean "is_locked", default: false
    t.boolean "is_public", default: false
    t.string "name", null: false
    t.string "password_digest"
    t.string "slug", null: false
    t.json "tags", default: []
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["is_public", "slug", "user_id"], name: "index_resumes_on_is_public_and_slug_and_user_id"
    t.index ["slug", "user_id"], name: "index_resumes_on_slug_and_user_id", unique: true
    t.index ["user_id", "updated_at"], name: "index_resumes_on_user_id_and_updated_at"
    t.index ["user_id"], name: "index_resumes_on_user_id"
  end

  create_table "sessions", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.string "user_id", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["token", "user_id"], name: "index_sessions_on_token_and_user_id"
    t.index ["token"], name: "index_sessions_on_token", unique: true
  end

  create_table "tool_calls", id: :string, force: :cascade do |t|
    t.json "arguments", default: {}
    t.datetime "created_at", null: false
    t.string "message_id", null: false
    t.string "name", null: false
    t.text "result"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
  end

  create_table "two_factors", id: :string, force: :cascade do |t|
    t.text "backup_codes"
    t.datetime "created_at", null: false
    t.string "otp_secret"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["user_id"], name: "index_two_factors_on_user_id"
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "display_username", null: false
    t.string "email", null: false
    t.boolean "email_verified", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "image"
    t.string "name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.boolean "two_factor_enabled", default: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["display_username"], name: "index_users_on_display_username", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end
end
