# frozen_string_literal: true

class UserCustomStatus < ApplicationRecord
  include BelongsToUser

  validates :slug, presence: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :label, presence: true, length: { maximum: 100 }
  validates :slug, uniqueness: { scope: :user_id }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
