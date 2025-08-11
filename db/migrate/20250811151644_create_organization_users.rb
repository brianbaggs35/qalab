class CreateOrganizationUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_users, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :role, default: 'member', null: false

      t.timestamps
    end
    
    add_index :organization_users, [:organization_id, :user_id], unique: true
    add_index :organization_users, :role
  end
end
