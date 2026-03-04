class CreatePasskeys < ActiveRecord::Migration[8.1]
  def change
    create_table :passkeys, id: :string do |t|
      t.string :user_id, null: false
      t.string :name
      t.string :aaguid
      t.text :public_key, null: false
      t.string :credential_id, null: false
      t.integer :counter, null: false, default: 0
      t.string :device_type, null: false
      t.boolean :backed_up, default: false
      t.text :transports
      t.timestamps

      t.index :user_id
      t.index :credential_id, unique: true
    end
  end
end
