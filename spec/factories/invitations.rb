FactoryBot.define do
  factory :invitation do
    sequence(:email) { |n| "user#{n}@example.com" }
    role { 'member' }
    expires_at { 7.days.from_now }
    accepted_at { nil }

    association :invited_by, factory: :user
    association :organization

    trait :admin_role do
      role { 'admin' }
    end

    trait :owner_role do
      role { 'owner' }
    end

    trait :organization_owner do
      role { 'organization_owner' }
      organization { nil }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { 1.day.ago }
    end
  end
end
