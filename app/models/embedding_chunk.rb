class EmbeddingChunk < ApplicationRecord
  include HasUuid

  has_neighbors :embedding

  belongs_to :document, polymorphic: true, foreign_key: :document_id, foreign_type: :document_type

  validates :chunk_text, presence: true
  validates :document_id, presence: true
  validates :document_type, presence: true

  after_destroy :remove_vector

  private

  def remove_vector
    # Vector is stored inline; destroyed with the record
  end
end
