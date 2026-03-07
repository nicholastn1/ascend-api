class CreateAiConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_configs, id: :string do |t|
      t.string :provider, null: false, default: "openai"
      t.string :model, null: false, default: "gpt-4o-mini"
      t.string :encrypted_api_key
      t.string :base_url

      t.timestamps
    end
  end
end
