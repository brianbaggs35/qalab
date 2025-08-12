class TestCasePolicy < ApplicationPolicy
  def index?
    user.present? && !user.system_admin?
  end

  def show?
    user.present? && !user.system_admin? && user_in_organization?
  end

  def new?
    user.present? && !user.system_admin? && user_in_organization?
  end

  def create?
    new?
  end

  def edit?
    user.present? && !user.system_admin? && user_owns_or_in_organization?
  end

  def update?
    edit?
  end

  def destroy?
    user.present? && !user.system_admin? && user_owns_or_in_organization?
  end

  class Scope < Scope
    def resolve
      if user.system_admin?
        scope.none
      else
        scope.joins(:organization)
             .where(organizations: { id: user.organizations.select(:id) })
      end
    end
  end

  private

  def user_in_organization?
    user.organizations.any?
  end

  def user_owns_or_in_organization?
    return false unless record

    record.user == user || user.organizations.include?(record.organization)
  end
end
