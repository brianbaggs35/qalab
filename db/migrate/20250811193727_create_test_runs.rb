class CreateTestRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :test_runs, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.text :description
      t.string :environment
      t.string :test_suite
      t.text :xml_file
      t.string :status, default: "pending", null: false
      t.jsonb :results_summary, default: {}
      t.uuid :organization_id, null: false
      t.uuid :user_id, null: false

      t.timestamps
    end

    # Add indexes for better performance
    add_index :test_runs, :organization_id
    add_index :test_runs, :user_id
    add_index :test_runs, :status
    add_index :test_runs, :environment
    add_index :test_runs, :created_at
    add_index :test_runs, [ :organization_id, :created_at ]

    # Add foreign key constraints
    add_foreign_key :test_runs, :organizations
    add_foreign_key :test_runs, :users
  end
end
