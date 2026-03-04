FactoryBot.define do
  factory :knowledge_document do
    user
    title { Faker::Book.title }
    source_type { "text" }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }

    trait :google_sheet do
      source_type { "google_sheet" }
      source_url { "https://docs.google.com/spreadsheets/d/#{SecureRandom.alphanumeric(44)}/edit" }
    end

    trait :file do
      source_type { "file" }
    end
  end
end
