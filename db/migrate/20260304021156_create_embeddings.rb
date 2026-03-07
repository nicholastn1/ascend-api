class CreateEmbeddings < ActiveRecord::Migration[8.1]
  def change
    # Regular table for chunk metadata (ActiveRecord-managed)
    create_table :embedding_chunks, id: :string do |t|
      t.string :document_id, null: false  # knowledge_document or resume ID
      t.string :document_type, null: false # "KnowledgeDocument" or "Resume"
      t.text :chunk_text, null: false
      t.integer :chunk_index, default: 0
      t.timestamps

      t.index [ :document_id, :document_type ]
      t.index [ :document_type ]
    end
  end

  # sqlite-vec virtual table is created separately in an initializer
  # because ActiveRecord schema:dump can't handle virtual tables
end
