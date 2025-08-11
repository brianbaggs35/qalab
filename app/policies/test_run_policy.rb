class TestRunPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.system_admin?
        scope.all
      else
        # Users can only see test runs from organizations they belong to
        user_org_ids = user.organizations.pluck(:id)
        scope.where(organization_id: user_org_ids)
      end
    end
  end

  def index?
    !user.system_admin?
  end

  def show?
    return false if user.system_admin?
    user_belongs_to_organization?
  end

  def create?
    return false if user.system_admin?
    true # Any authenticated non-system-admin user can create test runs
  end

  def update?
    return false if user.system_admin?
    user_owns_test_run? || user_can_manage_organization?
  end

  def destroy?
    return false if user.system_admin?
    user_owns_test_run? || user_can_manage_organization?
  end

  private

  def user_belongs_to_organization?
    user.organizations.exists?(id: record.organization_id)
  end

  def user_owns_test_run?
    record.user_id == user.id
  end

  def user_can_manage_organization?
    user.can_manage?(record.organization)
  end
end
