class JobApplicationHistory < ApplicationRecord
  belongs_to :application, class_name: "JobApplication"

  validates :to_status, presence: true, inclusion: { in: JobApplication::STATUSES }
  validates :from_status, inclusion: { in: JobApplication::STATUSES }, allow_nil: true
end
