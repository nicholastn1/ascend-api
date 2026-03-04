class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :string do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :username, null: false
      t.string :display_username, null: false
      t.string :image
      t.boolean :email_verified, default: false
      t.boolean :two_factor_enabled, default: false
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
      t.timestamps

      t.index :email, unique: true
      t.index :username, unique: true
      t.index :display_username, unique: true
      t.index :reset_password_token, unique: true
      t.index :confirmation_token, unique: true
    end
  end
end
