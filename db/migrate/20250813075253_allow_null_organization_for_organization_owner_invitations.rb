class AllowNullOrganizationForOrganizationOwnerInvitations < ActiveRecord::Migration[8.0]
  def change
    # Allow organization_id to be null for organization_owner invitations
    change_column_null :invitations, :organization_id, true
    
    # Also need to allow invited_by_id to be null for system admin created invitations
    change_column_null :invitations, :invited_by_id, true
  end
end
