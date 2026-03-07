class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages, id: :string do |t|
      t.string :conversation_id, null: false
      t.string :role, null: false
      t.text :content
      t.text :content_raw
      t.json :metadata
      t.integer :input_tokens
      t.integer :output_tokens
      t.timestamps

      t.index :conversation_id
      t.index [ :conversation_id, :created_at ]
    end
  end
end
