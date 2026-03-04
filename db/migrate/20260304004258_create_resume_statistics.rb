class CreateResumeStatistics < ActiveRecord::Migration[8.1]
  def change
    create_table :resume_statistics, id: :string do |t|
      t.string :resume_id, null: false
      t.integer :views, default: 0
      t.integer :downloads, default: 0
      t.datetime :last_viewed_at
      t.datetime :last_downloaded_at
      t.timestamps

      t.index :resume_id, unique: true
    end
  end
end
