FactoryBot.define do
  factory :api_key do
    user
    name { "Test API Key" }

    after(:build) do |api_key|
      if api_key.key_digest.blank?
        generated = ApiKey.generate_key
        api_key.key_digest = generated[:digest]
        api_key.key_start = generated[:key_start]
      end
    end
  end
end
