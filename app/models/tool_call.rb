class ToolCall < ApplicationRecord
  belongs_to :message

  validates :tool_call_id, presence: true
  validates :name, presence: true
end
