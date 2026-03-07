module Ai
  class ConfigureRubyLlm
    def self.call
      new.call
    end

    def call
      ai_config = AiConfig.instance
      api_key = ai_config.effective_api_key

      RubyLLM.configure do |config|
        config.openrouter_api_key = ENV["OPENROUTER_API_KEY"]
        config.openai_api_key = ENV["OPENAI_API_KEY"]
        config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
        config.gemini_api_key = ENV["GEMINI_API_KEY"]
        config.use_new_acts_as = true

        case ai_config.provider
        when "openai"
          config.openai_api_key = api_key if api_key.present?
          config.openai_api_base = ai_config.base_url if ai_config.base_url.present?
        when "anthropic"
          config.anthropic_api_key = api_key if api_key.present?
        when "gemini"
          config.gemini_api_key = api_key if api_key.present?
        when "openrouter"
          config.openrouter_api_key = api_key if api_key.present?
        when "ollama"
          config.openai_api_base = ai_config.base_url if ai_config.base_url.present?
        end
      end
    end
  end
end
