class TestRun < ApplicationRecord
  # Relationships
  belongs_to :organization
  belongs_to :user

  # Validations
  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  # Constants
  VALID_STATUSES = %w[pending processing completed failed].freeze

  # Scopes
  scope :for_organization, ->(org) { where(organization: org) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_environment, ->(env) { where(environment: env) }
  scope :recent, -> { order(created_at: :desc) }

  # Status methods
  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  # Results summary helpers
  def total_tests
    results_summary.dig("total_tests") || 0
  end

  def passed_tests
    results_summary.dig("passed") || 0
  end

  def failed_tests
    results_summary.dig("failed") || 0
  end

  def skipped_tests
    results_summary.dig("skipped") || 0
  end

  def success_rate
    return 0 if total_tests == 0
    (passed_tests.to_f / total_tests * 100).round(2)
  end

  # XML processing methods
  def process_xml_file
    return false if xml_file.blank?

    begin
      # This will be implemented to parse JUnit/TestNG XML
      update!(status: "processing")

      # TODO: Implement actual XML parsing
      # For now, set some sample data
      summary = {
        "total_tests" => 10,
        "passed" => 8,
        "failed" => 1,
        "skipped" => 1,
        "duration" => "5.2s"
      }

      update!(
        status: "completed",
        results_summary: summary
      )

      true
    rescue => e
      update!(status: "failed", results_summary: { "error" => e.message })
      false
    end
  end
end
