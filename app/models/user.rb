class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :oauth_accounts, dependent: :destroy
  has_one :two_factor, dependent: :destroy
  has_many :passkeys, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :resumes, dependent: :destroy
  has_many :job_applications, dependent: :destroy
  has_one :application_workflow, class_name: "UserApplicationWorkflow", dependent: :destroy
  has_many :custom_statuses, class_name: "UserCustomStatus", dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :knowledge_documents, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: { case_sensitive: false },
    format: { with: /\A[a-z0-9_-]+\z/ }, length: { in: 3..50 }
  validates :display_username, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true

  before_validation :normalize_email
  before_validation :set_display_username, on: :create

  # Override has_secure_password's password_digest column name
  alias_attribute :password_digest, :encrypted_password

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end

  def set_display_username
    self.display_username ||= username
  end
end
