FactoryBot.define do
  factory :test_case do
    title { "Login Functionality Test" }
    priority { "medium" }
    description { "Test the user login functionality with valid credentials" }
    steps { ["Navigate to login page", "Enter valid credentials", "Click submit"] }
    expected_results { "User should be successfully logged in and redirected to dashboard" }
    notes { {} }
    category { "functional" }
    status { "draft" }
    preconditions { "User account must exist in the system" }
    estimated_duration { 5 }
    tags { "login, authentication, regression" }
    
    association :user
    association :organization

    trait :high_priority do
      priority { "high" }
    end

    trait :ready do
      status { "ready" }
    end

    trait :approved do
      status { "approved" }
    end

    trait :with_many_steps do
      steps { (1..10).map { |i| "Test step #{i}" } }
    end
  end
end
