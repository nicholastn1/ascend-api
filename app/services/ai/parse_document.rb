module Ai
  class ParseDocument
    SUPPORTED_TYPES = {
      "pdf" => { system_slug: "pdf-parser-system", user_slug: "pdf-parser-user" },
      "docx" => { system_slug: "docx-parser-system", user_slug: "docx-parser-user" }
    }.freeze

    def initialize(file:, type:, model_id: nil)
      @file = file
      @type = type
      @model_id = model_id || AiConfig.instance.model.presence || ENV.fetch("DEFAULT_PARSE_MODEL", "openrouter/auto")
    end

    def call
      validate!
      Ai::ConfigureRubyLlm.call

      slugs = SUPPORTED_TYPES[@type]
      system_prompt = load_prompt(slugs[:system_slug])
      user_prompt = load_prompt(slugs[:user_slug])

      raise "Missing system prompt: #{slugs[:system_slug]}" unless system_prompt
      raise "Missing user prompt: #{slugs[:user_slug]}" unless user_prompt

      chat = RubyLLM.chat(model: @model_id)
      chat.with_instructions(system_prompt)

      # Send the file with the user prompt
      response = chat.ask(user_prompt, with: @file.tempfile.path)

      # Extract JSON from the response
      parse_json_response(response.content)
    end

    private

    def validate!
      raise ArgumentError, "No file provided" unless @file
      raise ArgumentError, "Unsupported type: #{@type}" unless SUPPORTED_TYPES.key?(@type)
    end

    def load_prompt(slug)
      AiPrompt.find_by(slug: slug)&.content
    end

    def parse_json_response(content)
      # Try to extract JSON from the response (may be wrapped in markdown code blocks)
      json_str = content
        &.gsub(/\A```(?:json)?\s*\n?/, "")
        &.gsub(/\n?```\s*\z/, "")
        &.strip

      JSON.parse(json_str)
    rescue JSON::ParserError => e
      raise "Failed to parse AI response as JSON: #{e.message}"
    end
  end
end
