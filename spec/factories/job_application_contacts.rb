FactoryBot.define do
  factory :job_application_contact do
    association :application, factory: :job_application
    name { Faker::Name.name }
    role { Faker::Job.title }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    linkedin_url { "https://linkedin.com/in/#{Faker::Internet.username}" }
  end
end
