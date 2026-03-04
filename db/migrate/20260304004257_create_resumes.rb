class CreateResumes < ActiveRecord::Migration[8.1]
  def change
    create_table :resumes, id: :string do |t|
      t.string :user_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.json :tags, default: []
      t.boolean :is_public, default: false
      t.boolean :is_locked, default: false
      t.string :password_digest
      t.json :data, null: false
      t.timestamps

      t.index :user_id
      t.index [:slug, :user_id], unique: true
      t.index [:user_id, :updated_at]
      t.index [:is_public, :slug, :user_id]
    end
  end
end
