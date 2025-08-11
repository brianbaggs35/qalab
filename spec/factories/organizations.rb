FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    settings { { timezone: "UTC", notifications: true } }
  end
end
