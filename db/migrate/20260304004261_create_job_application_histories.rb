class CreateJobApplicationHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :job_application_histories, id: :string do |t|
      t.string :application_id, null: false
      t.string :from_status
      t.string :to_status, null: false
      t.datetime :changed_at, default: -> { "CURRENT_TIMESTAMP" }

      t.index [:application_id, :changed_at]
    end
  end
end
