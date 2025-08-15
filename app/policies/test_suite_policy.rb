class TestSuitePolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.for_organization(user.organizations.first)
    end
  end

  def index?
    user_belongs_to_organization?
  end

  def show?
    user_belongs_to_organization? && same_organization?
  end

  def create?
    user_belongs_to_organization?
  end

  def new?
    create?
  end

  def update?
    user_belongs_to_organization? && same_organization?
  end

  def edit?
    update?
  end

  def destroy?
    user_belongs_to_organization? && same_organization? && (owner_or_admin? || record.user == user)
  end

  private

  def user_belongs_to_organization?
    user.organizations.any?
  end

  def same_organization?
    record.organization.in?(user.organizations)
  end

  def owner_or_admin?
    user.owner_of?(record.organization) || user.admin_of?(record.organization)
  end
end
