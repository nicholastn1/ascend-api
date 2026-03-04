class CreateJobApplicationContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :job_application_contacts, id: :string do |t|
      t.string :application_id, null: false
      t.string :name, null: false
      t.string :role
      t.string :email
      t.string :phone
      t.string :linkedin_url
      t.timestamps

      t.index :application_id
    end
  end
end
