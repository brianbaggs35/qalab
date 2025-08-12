class CreateTestCases < ActiveRecord::Migration[8.0]
  def change
    create_table :test_cases, id: :uuid do |t|
      t.string :title, null: false
      t.string :priority, null: false, default: 'medium'
      t.text :description
      t.jsonb :steps, default: []
      t.text :expected_results
      t.jsonb :notes, default: {}
      t.string :category, default: 'functional'
      t.string :status, default: 'draft'
      t.text :preconditions
      t.integer :estimated_duration
      t.text :tags
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :organization, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :test_cases, :priority
    add_index :test_cases, :category
    add_index :test_cases, :status
    add_index :test_cases, [:organization_id, :status]
  end
end
