FactoryBot.define do
  factory :test_result do
    association :test_run
    name { "MyString" }
    classname { "MyString" }
    status { "passed" }
    time { "9.99" }
    failure_message { "MyText" }
    failure_type { "MyString" }
    failure_stacktrace { "MyText" }

    trait :failed do
      status { "failed" }
    end

    trait :error do
      status { "error" }
    end

    trait :skipped do
      status { "skipped" }
    end
  end
end
