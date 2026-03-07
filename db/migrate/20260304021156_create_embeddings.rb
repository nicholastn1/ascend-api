class CreateEmbeddings < ActiveRecord::Migration[8.1]
  def change
    create_table :embedding_chunks, id: :string do |t|
      t.string :document_id, null: false
      t.string :document_type, null: false
      t.text :chunk_text, null: false
      t.integer :chunk_index, default: 0
      t.vector :embedding, limit: ENV.fetch("EMBEDDING_DIMENSIONS", 768).to_i
      t.timestamps

      t.index [ :document_id, :document_type ]
      t.index [ :document_type ]
    end
  end
end
