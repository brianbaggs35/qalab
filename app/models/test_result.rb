class TestResult < ApplicationRecord
  belongs_to :test_run

  # Validations
  validates :name, presence: true
  validates :status, inclusion: { in: %w[passed failed error skipped] }

  # Scopes
  scope :passed, -> { where(status: "passed") }
  scope :failed, -> { where(status: "failed") }
  scope :error, -> { where(status: "error") }
  scope :skipped, -> { where(status: "skipped") }
  scope :by_class, ->(classname) { where(classname: classname) }

  # Status helper methods
  def passed?
    status == "passed"
  end

  def failed?
    status == "failed"
  end

  def error?
    status == "error"
  end

  def skipped?
    status == "skipped"
  end

  def has_failure?
    failed? || error?
  end

  def full_stacktrace
    return nil unless has_failure?
    
    stacktrace = failure_stacktrace.presence
    message = failure_message.presence
    
    stacktrace || message
  end
end
