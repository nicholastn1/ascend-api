FactoryBot.define do
  factory :resume do
    user
    name { Faker::Job.title }
    slug { Faker::Internet.unique.slug(glue: "-").downcase.gsub(/[^a-z0-9-]/, "") }
    data { { basics: { name: Faker::Name.name, email: Faker::Internet.email } } }

    trait :public do
      is_public { true }
    end

    trait :locked do
      is_locked { true }
    end

    trait :with_password do
      password { "sharepass123" }
    end
  end
end
