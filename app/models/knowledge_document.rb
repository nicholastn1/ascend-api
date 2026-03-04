class KnowledgeDocument < ApplicationRecord
  include BelongsToUser

  SOURCE_TYPES = %w[google_sheet file text].freeze

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :title, presence: true
end
