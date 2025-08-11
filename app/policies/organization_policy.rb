class OrganizationPolicy < ApplicationPolicy
  def index?
    user.system_admin?
  end

  def show?
    user.system_admin? || user.organizations.include?(record)
  end

  def create?
    user.present? && !user.system_admin? # Regular users can create organizations
  end

  def update?
    user.system_admin? || user.can_manage?(record)
  end

  def destroy?
    user.system_admin? || user.owner_of?(record)
  end

  def manage_users?
    user.system_admin? || user.can_manage?(record)
  end

  def invite_users?
    user.system_admin? || user.can_manage?(record)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.system_admin?
        scope.all
      else
        scope.joins(:organization_users).where(organization_users: { user: user })
      end
    end
  end
end
