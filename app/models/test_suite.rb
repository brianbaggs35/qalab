class TestSuite < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  has_many :test_cases, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :name, uniqueness: { scope: :organization_id }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Scopes
  scope :for_organization, ->(org) { where(organization: org) }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def test_cases_count
    test_cases.count
  end

  def draft_test_cases_count
    test_cases.by_status(:draft).count
  end

  def ready_test_cases_count
    test_cases.by_status(:ready).count
  end

  def approved_test_cases_count
    test_cases.by_status(:approved).count
  end
end
