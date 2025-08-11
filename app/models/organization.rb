class Organization < ApplicationRecord
  # Relationships
  has_many :organization_users, dependent: :destroy
  has_many :users, through: :organization_users
  has_many :owners, -> { where(organization_users: { role: 'owner' }) }, through: :organization_users, source: :user
  has_many :admins, -> { where(organization_users: { role: 'admin' }) }, through: :organization_users, source: :user
  has_many :members, -> { where(organization_users: { role: 'member' }) }, through: :organization_users, source: :user
  
  # Validations
  validates :name, presence: true, uniqueness: true
  
  # Serialized attributes for settings
  serialize :settings, coder: JSON
  
  # After create callback to set up the creator as owner
  after_create :create_owner_relationship
  
  private
  
  def create_owner_relationship
    # This will be called from the controller when we have the current_user context
  end
end
