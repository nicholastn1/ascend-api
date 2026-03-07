class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :string do |t|
      t.string :user_id, null: false
      t.string :token, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :expires_at, null: false
      t.timestamps

      t.index :token, unique: true
      t.index [ :token, :user_id ]
      t.index :expires_at
    end
  end
end
