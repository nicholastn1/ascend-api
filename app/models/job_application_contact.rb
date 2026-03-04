class JobApplicationContact < ApplicationRecord
  belongs_to :application, class_name: "JobApplication"

  validates :name, presence: true
end
