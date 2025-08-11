FactoryBot.define do
  factory :organization_user do
    association :organization
    association :user
    role { "member" }

    trait :owner do
      role { "owner" }
    end

    trait :admin do
      role { "admin" }
    end
  end
end
