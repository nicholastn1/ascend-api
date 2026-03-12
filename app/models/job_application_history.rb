class JobApplicationHistory < ApplicationRecord
  belongs_to :application, class_name: "JobApplication"

  validates :to_status, presence: true
  validate :to_status_in_valid_set
  validate :from_status_in_valid_set

  private

  def valid_statuses
    @valid_statuses ||= JobApplication::STATUSES + application&.user&.custom_statuses&.pluck(:slug).to_a
  end

  def to_status_in_valid_set
    return if to_status.blank?
    errors.add(:to_status, "is not included in the list") unless valid_statuses.include?(to_status)
  end

  def from_status_in_valid_set
    return if from_status.blank?
    errors.add(:from_status, "is not included in the list") unless valid_statuses.include?(from_status)
  end
end
