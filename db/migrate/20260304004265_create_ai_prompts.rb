class CreateAiPrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_prompts, id: :string do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :description
      t.text :content, null: false
      t.timestamps

      t.index :slug, unique: true
    end
  end
end
