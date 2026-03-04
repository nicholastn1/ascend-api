class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys, id: :string do |t|
      t.string :user_id, null: false
      t.string :name
      t.string :prefix
      t.string :key_digest, null: false
      t.string :key_start
      t.boolean :enabled, default: true
      t.text :permissions
      t.json :metadata
      t.boolean :rate_limit_enabled, default: false
      t.integer :rate_limit_time_window
      t.integer :rate_limit_max
      t.integer :request_count, default: 0
      t.integer :remaining
      t.datetime :last_request_at
      t.integer :refill_interval
      t.integer :refill_amount
      t.datetime :last_refill_at
      t.datetime :expires_at
      t.timestamps

      t.index :user_id
      t.index :key_digest, unique: true
      t.index [:enabled, :user_id]
    end
  end
end
