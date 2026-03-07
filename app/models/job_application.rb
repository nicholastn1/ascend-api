class JobApplication < ApplicationRecord
  include BelongsToUser

  STATUSES = %w[applied screening interviewing offer accepted rejected withdrawn].freeze

  has_many :contacts, class_name: "JobApplicationContact",
    foreign_key: :application_id, dependent: :destroy
  has_many :histories, class_name: "JobApplicationHistory",
    foreign_key: :application_id, dependent: :destroy

  validates :company_name, presence: true
  validates :job_title, presence: true
  validates :current_status, inclusion: { in: STATUSES }

  scope :by_status, ->(status) { where(current_status: status) }
  scope :ordered, -> { order(created_at: :desc) }
end
