class AddTestSuiteToTestCases < ActiveRecord::Migration[8.0]
  def change
    add_column :test_cases, :test_suite_id, :uuid
    add_index :test_cases, :test_suite_id
    add_foreign_key :test_cases, :test_suites
  end
end
