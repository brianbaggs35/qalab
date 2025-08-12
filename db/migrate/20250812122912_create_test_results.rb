class CreateTestResults < ActiveRecord::Migration[8.0]
  def change
    create_table :test_results, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :test_run_id, null: false
      t.string :name, null: false
      t.string :classname
      t.string :status, null: false, default: 'passed'
      t.decimal :time, precision: 10, scale: 3
      t.text :failure_message
      t.string :failure_type
      t.text :failure_stacktrace
      t.text :system_out
      t.text :system_err

      t.timestamps
    end

    # Add indexes for better performance
    add_index :test_results, :test_run_id
    add_index :test_results, :status
    add_index :test_results, :classname
    add_index :test_results, [:test_run_id, :status]
    add_index :test_results, [:test_run_id, :classname]

    # Add foreign key constraint
    add_foreign_key :test_results, :test_runs
  end
end
