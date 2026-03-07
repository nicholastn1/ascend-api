class CreateModels < ActiveRecord::Migration[8.1]
  def change
    create_table :models, id: :string do |t|
      t.string :model_id
      t.string :provider
      t.string :display_name
      t.integer :context_window
      t.integer :max_tokens
      t.boolean :supports_vision
      t.boolean :supports_functions
      t.boolean :supports_json_mode
      t.decimal :input_price_per_million
      t.decimal :output_price_per_million

      t.timestamps

      t.index [ :model_id, :provider ], unique: true
    end
  end
end
