# frozen_string_literal: true

class UserApplicationWorkflow < ApplicationRecord
  include BelongsToUser

  validates :user_id, uniqueness: true

  def status_slugs
    super || []
  end

  def status_slugs=(value)
    super(value.is_a?(Array) ? value : [])
  end
end
