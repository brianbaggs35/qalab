FactoryBot.define do
  factory :test_run do
    sequence(:name) { |n| "Test Run #{n}" }
    description { "Sample test run for automated testing" }
    environment { %w[development staging production].sample }
    test_suite { "smoke_tests" }
    xml_file { "<testsuites><testsuite name='SampleTest' tests='10' failures='1' skipped='0' time='5.2'></testsuite></testsuites>" }
    status { "pending" }
    results_summary { {} }

    association :organization
    association :user

    trait :completed do
      status { "completed" }
      results_summary do
        {
          "total_tests" => 10,
          "passed" => 8,
          "failed" => 1,
          "skipped" => 1,
          "duration" => "5.2s"
        }
      end
    end

    trait :failed do
      status { "failed" }
      results_summary do
        {
          "error" => "Processing failed"
        }
      end
    end

    trait :processing do
      status { "processing" }
    end

    trait :with_large_results do
      results_summary do
        {
          "total_tests" => 1000,
          "passed" => 950,
          "failed" => 30,
          "skipped" => 20,
          "duration" => "120.5s"
        }
      end
    end
  end
end
