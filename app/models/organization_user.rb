class OrganizationUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  # Validations
  validates :role, inclusion: { in: User::ORGANIZATION_ROLES }
  validates :user_id, uniqueness: { scope: :organization_id }

  # Scopes
  scope :owners, -> { where(role: "owner") }
  scope :admins, -> { where(role: "admin") }
  scope :members, -> { where(role: "member") }
  scope :managers, -> { where(role: %w[owner admin]) }

  # Role checking methods
  def owner?
    role == "owner"
  end

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  def manager?
    %w[owner admin].include?(role)
  end
end
