class CreateUserCustomStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :user_custom_statuses, id: :string do |t|
      t.string :user_id, null: false
      t.string :slug, null: false
      t.string :label, null: false
      t.string :color
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :user_custom_statuses, [:user_id, :slug], unique: true
    add_foreign_key :user_custom_statuses, :users
  end
end
