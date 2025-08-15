FactoryBot.define do
  factory :test_suite do
    sequence(:name) { |n| "Test Suite #{n}" }
    description { "Sample test suite for organizing test cases" }
    
    association :organization
    association :user

    trait :with_test_cases do
      after(:create) do |test_suite|
        create_list(:test_case, 3, test_suite: test_suite, organization: test_suite.organization, user: test_suite.user)
      end
    end

    trait :empty do
      # No test cases
    end
  end
end
