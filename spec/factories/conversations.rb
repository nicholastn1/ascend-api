FactoryBot.define do
  factory :conversation do
    user
    title { "Test Conversation" }
    agent_type { "general" }
    model_id { "openrouter/auto" }
  end
end
