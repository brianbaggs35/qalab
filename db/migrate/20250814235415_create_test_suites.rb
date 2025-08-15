class CreateTestSuites < ActiveRecord::Migration[8.0]
  def change
    # Enable UUID extension if not already enabled
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :test_suites, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.uuid :organization_id, null: false
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :test_suites, :organization_id
    add_index :test_suites, :user_id
    add_index :test_suites, [:organization_id, :name], unique: true

    add_foreign_key :test_suites, :organizations
    add_foreign_key :test_suites, :users
  end
end
