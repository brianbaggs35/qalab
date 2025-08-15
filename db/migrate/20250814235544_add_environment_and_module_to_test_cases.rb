class AddEnvironmentAndModuleToTestCases < ActiveRecord::Migration[8.0]
  def change
    add_column :test_cases, :environment, :string
    add_column :test_cases, :module, :string
  end
end
