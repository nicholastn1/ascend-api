class Resume < ApplicationRecord
  include BelongsToUser

  has_one :statistics, class_name: "ResumeStatistic", dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :user_id },
    format: { with: /\A[a-z0-9-]+\z/ }
  validates :data, presence: true

  has_secure_password :password, validations: false

  before_create :create_statistics_record

  scope :ordered, -> { order(updated_at: :desc) }
  scope :public_resumes, -> { where(is_public: true) }

  def locked?
    is_locked
  end

  def password_protected?
    password_digest.present?
  end

  private

  def create_statistics_record
    build_statistics
  end
end
