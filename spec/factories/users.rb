FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    username { Faker::Internet.unique.username(specifier: 5..15, separators: %w[_ -]).gsub(/[^a-z0-9_-]/, "") }
    password { "password123" }

    trait :verified do
      email_verified { true }
      confirmed_at { Time.current }
    end
  end
end
