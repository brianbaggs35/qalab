class InvitationPolicy < ApplicationPolicy
  def index?
    user_can_manage_invitations?
  end

  def show?
    user_can_manage_invitations? && invitation_belongs_to_user_organization?
  end

  def new?
    user_can_manage_invitations?
  end

  def create?
    user_can_manage_invitations? && can_invite_role?
  end

  def destroy?
    user_can_manage_invitations? && invitation_belongs_to_user_organization?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.system_admin?
        scope.all
      else
        # Only show invitations for organizations where user has admin/owner role
        organization_ids = user.organization_users
                              .where(role: ['owner', 'admin'])
                              .pluck(:organization_id)
        scope.where(organization_id: organization_ids)
      end
    end
  end

  private

  def user_can_manage_invitations?
    return true if user.system_admin?
    
    # User must be owner or admin of at least one organization
    user.organization_users.where(role: ['owner', 'admin']).exists?
  end

  def invitation_belongs_to_user_organization?
    return true if user.system_admin?
    
    organization_ids = user.organization_users
                          .where(role: ['owner', 'admin'])
                          .pluck(:organization_id)
    organization_ids.include?(record.organization_id)
  end

  def can_invite_role?
    return true if user.system_admin?
    
    # Get user's highest role in the organization
    user_role = user.organization_users
                   .find_by(organization: record.organization)
                   &.role
    
    case user_role
    when 'owner'
      # Owners can invite anyone
      ['owner', 'admin', 'member'].include?(record.role)
    when 'admin'
      # Admins can invite admins and members, but not owners
      ['admin', 'member'].include?(record.role)
    else
      # Members cannot invite anyone
      false
    end
  end
end
