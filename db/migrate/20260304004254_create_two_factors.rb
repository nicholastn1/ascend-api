class CreateTwoFactors < ActiveRecord::Migration[8.1]
  def change
    create_table :two_factors, id: :string do |t|
      t.string :user_id, null: false
      t.string :otp_secret
      t.text :backup_codes
      t.timestamps

      t.index :user_id
    end
  end
end
