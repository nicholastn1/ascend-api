FactoryBot.define do
  factory :job_application do
    user
    company_name { Faker::Company.name }
    job_title { Faker::Job.title }
    current_status { "applied" }
    job_url { Faker::Internet.url }
    notes { Faker::Lorem.paragraph }
    application_date { Date.current }
  end
end
