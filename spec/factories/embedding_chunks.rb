FactoryBot.define do
  factory :embedding_chunk do
    association :document, factory: :knowledge_document
    chunk_text { Faker::Lorem.paragraph(sentence_count: 5) }
    chunk_index { 0 }
  end
end
