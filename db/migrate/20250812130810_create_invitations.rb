class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.string :role, null: false, default: 'member'
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      
      # Foreign keys
      t.references :invited_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :organization, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    
    add_index :invitations, :token, unique: true
    add_index :invitations, [:email, :organization_id], unique: true, where: 'accepted_at IS NULL'
    add_index :invitations, :expires_at
  end
end
