class Invitation < ApplicationRecord
  # Relationships
  belongs_to :invited_by, class_name: 'User'
  belongs_to :organization

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[owner admin member] }
  validates :expires_at, presence: true
  validate :email_not_already_registered
  validate :email_unique_per_organization, unless: :accepted?

  # Scopes
  scope :pending, -> { where(accepted_at: nil) }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  scope :valid_invitations, -> { pending.where('expires_at >= ?', Time.current) }
  
  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  # Status methods
  def accepted?
    accepted_at.present?
  end

  def expired?
    expires_at < Time.current
  end

  def valid_invitation?
    !accepted? && !expired?
  end

  def accept!
    update!(accepted_at: Time.current) if valid_invitation?
  end

  # Token methods
  def self.find_by_token(token)
    find_by(token: token)
  end

  def self.find_valid_invitation(token)
    find_by_token(token)&.tap do |invitation|
      return nil unless invitation&.valid_invitation?
    end
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32) if token.blank?
  end

  def set_expiration
    self.expires_at = 7.days.from_now if expires_at.blank?
  end

  def email_not_already_registered
    return unless email.present?
    
    if User.exists?(email: email)
      errors.add(:email, 'is already registered')
    end
  end

  def email_unique_per_organization
    return unless email.present? && organization_id.present?
    
    if self.class.pending.where(email: email, organization: organization).where.not(id: id).exists?
      errors.add(:email, 'has already been invited to this organization')
    end
  end
end
