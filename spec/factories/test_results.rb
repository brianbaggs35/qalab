FactoryBot.define do
  factory :test_result do
    test_run { nil }
    name { "MyString" }
    classname { "MyString" }
    status { "MyString" }
    time { "9.99" }
    failure_message { "MyText" }
    failure_type { "MyString" }
    failure_stacktrace { "MyText" }
  end
end
