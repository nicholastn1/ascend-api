class KnowledgeDocument < ApplicationRecord
  include BelongsToUser

  SOURCE_TYPES = %w[google_sheet file text].freeze

  has_many :embedding_chunks, as: :document, dependent: :destroy

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :title, presence: true
  validates :source_url, presence: true, if: -> { source_type == "google_sheet" }
end
