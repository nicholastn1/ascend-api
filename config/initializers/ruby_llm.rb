RubyLLM.configure do |config|
  config.openrouter_api_key = ENV["OPENROUTER_API_KEY"]
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.gemini_api_key = ENV["GEMINI_API_KEY"]

  config.use_new_acts_as = true
end

Rails.application.config.after_initialize do
  if ActiveRecord::Base.connection.table_exists?(:ai_configs)
    ai_config = AiConfig.instance
    key = ai_config.encrypted_api_key
    if key.present?
      RubyLLM.configure do |config|
        case ai_config.provider
        when "openai" then config.openai_api_key = key
        when "anthropic" then config.anthropic_api_key = key
        when "gemini" then config.gemini_api_key = key
        when "openrouter" then config.openrouter_api_key = key
        end
      end
    end
  end
rescue => e
  Rails.logger.warn("Failed to load AI config from DB: #{e.message}")
end
