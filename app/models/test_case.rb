class TestCase < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  # Enums
  enum :priority, { low: "low", medium: "medium", high: "high", critical: "critical" }, default: :medium
  enum :category, {
    functional: "functional",
    ui_ux: "ui_ux",
    integration: "integration",
    performance: "performance",
    security: "security",
    regression: "regression"
  }, default: :functional
  enum :status, {
    draft: "draft",
    ready: "ready",
    in_review: "in_review",
    approved: "approved",
    deprecated: "deprecated"
  }, default: :draft

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :priority, inclusion: { in: priorities.keys }
  validates :category, inclusion: { in: categories.keys }
  validates :status, inclusion: { in: statuses.keys }
  validates :expected_results, presence: true
  validates :estimated_duration, numericality: { greater_than: 0, less_than_or_equal_to: 300 }, allow_nil: true

  # JSONB field defaults
  attribute :steps, :jsonb, default: []
  attribute :notes, :jsonb, default: {}

  # Scopes
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_organization, ->(org) { where(organization: org) }

  # Methods
  def tag_list
    return [] if tags.blank?
    tags.split(",").map(&:strip).reject(&:blank?)
  end

  def tag_list=(list)
    self.tags = Array(list).map(&:strip).reject(&:blank?).join(", ")
  end

  def steps_list
    return [] unless steps.is_a?(Array)
    steps
  end

  def add_step(step_text)
    self.steps = steps_list + [ step_text.strip ] if step_text.present?
  end

  def remove_step(index)
    steps_array = steps_list
    steps_array.delete_at(index.to_i) if index.to_i >= 0 && index.to_i < steps_array.length
    self.steps = steps_array
  end

  def priority_badge_class
    case priority
    when "critical"
      "badge-error"
    when "high"
      "badge-warning"
    when "medium"
      "badge-info"
    when "low"
      "badge-neutral"
    else
      "badge-ghost"
    end
  end

  def status_badge_class
    case status
    when "approved"
      "badge-success"
    when "ready", "in_review"
      "badge-info"
    when "draft"
      "badge-warning"
    when "deprecated"
      "badge-neutral"
    else
      "badge-ghost"
    end
  end
end
