class Conversation < ApplicationRecord
  include BelongsToUser

  has_many :messages, dependent: :destroy

  scope :ordered, -> { order(updated_at: :desc) }
end
