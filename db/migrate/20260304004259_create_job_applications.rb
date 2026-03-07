class CreateJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :job_applications, id: :string do |t|
      t.string :user_id, null: false
      t.string :current_status, default: "applied"
      t.string :company_name, null: false
      t.string :job_title, null: false
      t.string :job_url
      t.decimal :salary_amount
      t.string :salary_currency, default: "USD"
      t.string :salary_period
      t.text :notes
      t.date :application_date
      t.timestamps

      t.index [ :user_id, :current_status ]
      t.index [ :user_id, :created_at ]
      t.index [ :user_id, :company_name ]
    end
  end
end
