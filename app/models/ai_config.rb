class AiConfig < ApplicationRecord
  SINGLETON_ID = "global".freeze

  PROVIDERS = %w[openai anthropic gemini openrouter ollama].freeze
  PROVIDER_KEY_MAP = {
    "openai" => "OPENAI_API_KEY",
    "anthropic" => "ANTHROPIC_API_KEY",
    "gemini" => "GEMINI_API_KEY",
    "openrouter" => "OPENROUTER_API_KEY"
  }.freeze

  validates :provider, inclusion: { in: PROVIDERS }
  validates :model, presence: true

  encrypts :encrypted_api_key

  def self.instance
    find_or_create_by!(id: SINGLETON_ID) do |config|
      config.provider = ENV.fetch("DEFAULT_AI_PROVIDER", "openai")
      config.model = ENV.fetch("DEFAULT_CHAT_MODEL", "gpt-4o-mini")
    end
  end

  def effective_api_key
    encrypted_api_key.presence || env_api_key
  end

  def has_api_key?
    effective_api_key.present?
  end

  def configured?
    model.present? && has_api_key?
  end

  private

  def env_api_key
    env_var = PROVIDER_KEY_MAP[provider]
    env_var ? ENV[env_var] : nil
  end
end
