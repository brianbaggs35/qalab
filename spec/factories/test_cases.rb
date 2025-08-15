FactoryBot.define do
  factory :test_case do
    sequence(:title) { |n| "Test Case #{n}" }
    priority { "medium" }
    description { "Sample test case description with rich text content" }
    steps { [ "Navigate to login page", "Enter valid credentials", "Click submit" ] }
    expected_results { "User should be successfully logged in and redirected to dashboard" }
    notes { {} }
    category { "functional" }
    status { "draft" }
    preconditions { "User account must exist in the system" }
    estimated_duration { 5 }
    tags { "login, authentication, regression" }
    environment { "staging" }

    association :user
    association :organization
    
    # Optional test_suite association
    test_suite { nil }

    # Handle the 'module' reserved keyword by using after(:build) callback
    after(:build) do |test_case|
      test_case['module'] = "authentication"
    end

    trait :with_test_suite do
      association :test_suite
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :ready do
      status { "ready" }
    end

    trait :approved do
      status { "approved" }
    end

    trait :ui_ux_category do
      category { "ui_ux" }
    end

    trait :with_many_steps do
      steps { (1..10).map { |i| "Test step #{i}" } }
    end

    trait :with_long_description do
      description { "This is a very detailed test case description that contains multiple paragraphs and detailed instructions for the tester to follow during execution." }
    end
  end
end
