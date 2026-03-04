class EmbeddingChunk < ApplicationRecord
  include HasUuid

  belongs_to :document, polymorphic: true, foreign_key: :document_id, foreign_type: :document_type

  validates :chunk_text, presence: true
  validates :document_id, presence: true
  validates :document_type, presence: true

  after_destroy :remove_vector

  private

  def remove_vector
    VectorSearch.delete(chunk_id: id)
  rescue => e
    Rails.logger.warn("Failed to remove vector for chunk #{id}: #{e.message}")
  end
end
