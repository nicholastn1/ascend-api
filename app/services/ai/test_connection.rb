module Ai
  class TestConnection
    def initialize(model_id: nil)
      @model_id = model_id || AiConfig.instance.model.presence || ENV.fetch("DEFAULT_CHAT_MODEL", "openrouter/auto")
    end

    def call
      Ai::ConfigureRubyLlm.call
      chat = RubyLLM.chat(model: @model_id)
      response = chat.ask("Respond with exactly: OK")

      {
        success: true,
        model: @model_id,
        response: response.content&.strip
      }
    rescue => e
      {
        success: false,
        model: @model_id,
        error: e.message
      }
    end
  end
end
