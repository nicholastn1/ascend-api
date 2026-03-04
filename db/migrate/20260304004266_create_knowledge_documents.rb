class CreateKnowledgeDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_documents, id: :string do |t|
      t.string :user_id, null: false
      t.string :source_type, null: false
      t.string :source_url
      t.string :title, null: false
      t.text :content
      t.json :metadata
      t.datetime :last_synced_at
      t.timestamps

      t.index :user_id
      t.index [:user_id, :source_type]
    end
  end
end
