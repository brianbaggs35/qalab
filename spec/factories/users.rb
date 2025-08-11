FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { "SecurePassword123!" }
    password_confirmation { "SecurePassword123!" }
    role { "member" }
    confirmed_at { Time.current }

    trait :system_admin do
      role { "system_admin" }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :locked do
      locked_at { 1.hour.ago }
    end
  end
end
