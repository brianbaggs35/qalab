class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  # Relationships
  has_many :organization_users, dependent: :destroy
  has_many :organizations, through: :organization_users

  # Validations
  validates :first_name, :last_name, presence: true
  validates :role, inclusion: { in: %w[system_admin member] }

  # Enums for roles - system-wide roles
  SYSTEM_ROLES = %w[system_admin member].freeze

  # Organization-specific roles (in organization_users table)
  ORGANIZATION_ROLES = %w[owner admin member].freeze

  # Scopes
  scope :system_admins, -> { where(role: "system_admin") }
  scope :regular_users, -> { where(role: "member") }

  # Role checking methods
  def system_admin?
    role == "system_admin"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  # Get role in a specific organization
  def role_in_organization(organization)
    organization_users.find_by(organization: organization)&.role
  end

  # Check if user has a specific role in an organization
  def has_role_in_organization?(organization, role_name)
    role_in_organization(organization) == role_name.to_s
  end

  # Check if user is owner of an organization
  def owner_of?(organization)
    has_role_in_organization?(organization, :owner)
  end

  # Check if user is admin of an organization
  def admin_of?(organization)
    has_role_in_organization?(organization, :admin)
  end

  # Check if user can manage an organization (owner or admin)
  def can_manage?(organization)
    %w[owner admin].include?(role_in_organization(organization))
  end
end
