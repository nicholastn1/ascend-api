class CreateOauthAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_accounts, id: :string do |t|
      t.string :user_id, null: false
      t.string :provider, null: false
      t.string :provider_uid, null: false
      t.string :access_token
      t.string :refresh_token
      t.datetime :token_expires_at
      t.string :scope
      t.string :id_token
      t.timestamps

      t.index [:provider, :provider_uid], unique: true
      t.index :user_id
    end
  end
end
