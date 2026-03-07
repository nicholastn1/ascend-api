class AddSecurityImprovements < ActiveRecord::Migration[8.1]
  def change
    # Store password reset tokens as digests, not plaintext
    add_column :users, :reset_password_token_digest, :string
    add_index :users, :reset_password_token_digest, unique: true

    # Unique constraint on two_factors.user_id (has_one relationship)
    add_index :two_factors, :user_id, unique: true, name: "index_two_factors_on_user_id_unique"
    remove_index :two_factors, :user_id, name: "index_two_factors_on_user_id", if_exists: true

    # Foreign key constraints for data integrity
    add_foreign_key :sessions, :users
    add_foreign_key :oauth_accounts, :users
    add_foreign_key :two_factors, :users
    add_foreign_key :passkeys, :users
    add_foreign_key :api_keys, :users
    add_foreign_key :resumes, :users
    add_foreign_key :resume_statistics, :resumes
    add_foreign_key :job_applications, :users
    add_foreign_key :job_application_contacts, :job_applications, column: :application_id
    add_foreign_key :job_application_histories, :job_applications, column: :application_id
    add_foreign_key :conversations, :users
    add_foreign_key :messages, :conversations
    add_foreign_key :tool_calls, :messages
    add_foreign_key :knowledge_documents, :users
  end
end
