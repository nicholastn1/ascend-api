class CreateToolCalls < ActiveRecord::Migration[8.1]
  def change
    create_table :tool_calls, id: :string do |t|
      t.string :message_id, null: false
      t.string :tool_call_id, null: false
      t.string :name, null: false
      t.json :arguments, default: {}
      t.text :result
      t.timestamps

      t.index :message_id
    end
  end
end
