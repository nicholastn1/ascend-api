class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations, id: :string do |t|
      t.string :user_id, null: false
      t.string :title
      t.string :agent_type, default: "general"
      t.string :model_id
      t.timestamps

      t.index :user_id
      t.index [ :user_id, :updated_at ]
    end
  end
end
