class CreateUserApplicationWorkflows < ActiveRecord::Migration[8.1]
  def change
    create_table :user_application_workflows, id: :string do |t|
      t.string :user_id, null: false
      t.jsonb :status_slugs, default: []

      t.timestamps
    end

    add_index :user_application_workflows, :user_id, unique: true
    add_foreign_key :user_application_workflows, :users
  end
end
