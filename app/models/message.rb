class Message < ApplicationRecord
  ROLES = %w[user assistant system tool].freeze

  belongs_to :conversation
  has_many :tool_calls, dependent: :destroy

  validates :role, presence: true, inclusion: { in: ROLES }

  scope :ordered, -> { order(created_at: :asc) }
end
