class Organization < ApplicationRecord
  # Relationships
  has_many :organization_users, dependent: :destroy
  has_many :users, through: :organization_users
  has_many :owners, -> { where(organization_users: { role: "owner" }) }, through: :organization_users, source: :user
  has_many :admins, -> { where(organization_users: { role: "admin" }) }, through: :organization_users, source: :user
  has_many :members, -> { where(organization_users: { role: "member" }) }, through: :organization_users, source: :user
  has_many :test_runs, dependent: :destroy
  has_many :test_cases, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true

  # Serialized attributes for settings
  serialize :settings, coder: JSON

  # After create callback to set up the creator as owner
  after_create :create_owner_relationship

  # Statistics methods
  def total_test_runs
    test_runs.count
  end

  def test_runs_this_month
    test_runs.where(created_at: 1.month.ago..Time.current).count
  end

  def success_rate
    completed_runs = test_runs.where(status: "completed")
    return 0 if completed_runs.empty?

    total_tests = completed_runs.sum { |run| run.total_tests }
    passed_tests = completed_runs.sum { |run| run.passed_tests }

    return 0 if total_tests == 0
    (passed_tests.to_f / total_tests * 100).round(2)
  end

  private

  def create_owner_relationship
    # This will be called from the controller when we have the current_user context
  end
end
