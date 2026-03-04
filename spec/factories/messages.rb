FactoryBot.define do
  factory :message do
    conversation
    role { "user" }
    content { "Hello, how are you?" }
  end
end
