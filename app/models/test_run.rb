class TestRun < ApplicationRecord
  # Relationships
  belongs_to :organization
  belongs_to :user
  has_many :test_results, dependent: :destroy

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
      update!(status: "processing")

      # Parse the XML content directly from the text field
      doc = Nokogiri::XML(xml_file)

      # Detect format and parse accordingly
      if junit_format?(doc)
        parse_junit_xml(doc)
      elsif testng_format?(doc)
        parse_testng_xml(doc)
      else
        raise "Unsupported XML format. Please upload JUnit or TestNG XML files."
      end

      true
    rescue => e
      Rails.logger.error "XML processing failed: #{e.message}"
      update!(status: "failed", results_summary: { "error" => e.message })
      false
    end
  end

  private

  def junit_format?(doc)
    doc.xpath("//testsuite").any? || doc.xpath("//testsuites").any?
  end

  def testng_format?(doc)
    doc.xpath("//testng-results").any? || doc.xpath("//suite").any?
  end

  def parse_junit_xml(doc)
    # Handle both single testsuite and testsuites with multiple suites
    testsuites = doc.xpath("//testsuite")

    total_tests = 0
    passed = 0
    failed = 0
    errors = 0
    skipped = 0
    total_time = 0.0

    testsuites.each do |testsuite|
      suite_tests = testsuite.attr("tests").to_i
      suite_failures = testsuite.attr("failures").to_i
      suite_errors = testsuite.attr("errors").to_i
      suite_skipped = testsuite.attr("skipped").to_i
      suite_time = testsuite.attr("time").to_f

      total_tests += suite_tests
      failed += suite_failures
      errors += suite_errors
      skipped += suite_skipped
      total_time += suite_time

      # Parse individual test cases
      testsuite.xpath(".//testcase").each do |testcase|
        parse_test_case(testcase)
      end
    end

    # Calculate passed tests
    passed = total_tests - failed - errors - skipped

    # Update summary
    summary = {
      "total_tests" => total_tests,
      "passed" => passed,
      "failed" => failed,
      "errors" => errors,
      "skipped" => skipped,
      "duration" => "#{total_time}s",
      "parsed_at" => Time.current.iso8601,
      "format" => "JUnit"
    }

    update!(
      status: "completed",
      results_summary: summary
    )
  end

  def parse_testng_xml(doc)
    # Handle TestNG XML format - can have multiple suites
    suites = doc.xpath("//suite")

    total_tests = 0
    passed = 0
    failed = 0
    skipped = 0
    total_time = 0.0

    suites.each do |suite|
      # Parse tests within each suite
      tests = suite.xpath(".//test")

      tests.each do |test|
        classes = test.xpath(".//class")

        classes.each do |test_class|
          class_name = test_class.attr("name")

          # Parse test methods
          test_methods = test_class.xpath(".//test-method[@is-config='false']")

          test_methods.each do |method|
            method_name = method.attr("name")
            status = method.attr("status")
            duration = method.attr("duration-ms").to_f / 1000.0 # Convert ms to seconds

            total_tests += 1
            total_time += duration

            case status
            when "PASS"
              passed += 1
              test_status = "passed"
            when "FAIL"
              failed += 1
              test_status = "failed"
            when "SKIP"
              skipped += 1
              test_status = "skipped"
            else
              test_status = "passed" # Default to passed if unknown
              passed += 1
            end

            # Look for exception information
            failure_message = nil
            failure_type = nil
            failure_stacktrace = nil

            exception = method.at_xpath(".//exception")
            if exception
              failure_message = exception.attr("message")
              failure_type = exception.attr("class")
              failure_stacktrace = exception.text.strip
            end

            # Create test result
            test_results.create!(
              name: method_name,
              classname: class_name,
              status: test_status,
              time: duration,
              failure_message: failure_message,
              failure_type: failure_type,
              failure_stacktrace: failure_stacktrace
            )
          end
        end
      end
    end

    # Update summary
    summary = {
      "total_tests" => total_tests,
      "passed" => passed,
      "failed" => failed,
      "errors" => 0, # TestNG doesn't separate errors from failures
      "skipped" => skipped,
      "duration" => "#{total_time}s",
      "parsed_at" => Time.current.iso8601,
      "format" => "TestNG"
    }

    update!(
      status: "completed",
      results_summary: summary
    )
  end

  def parse_test_case(testcase_node)
    name = testcase_node.attr("name")
    classname = testcase_node.attr("classname")
    time = testcase_node.attr("time").to_f

    status = "passed"
    failure_message = nil
    failure_type = nil
    failure_stacktrace = nil
    system_out = nil
    system_err = nil

    # Check for failure
    failure = testcase_node.at_xpath("failure")
    if failure
      status = "failed"
      failure_message = failure.attr("message")
      failure_type = failure.attr("type")
      failure_stacktrace = failure.content
    end

    # Check for error
    error = testcase_node.at_xpath("error")
    if error
      status = "error"
      failure_message = error.attr("message")
      failure_type = error.attr("type")
      failure_stacktrace = error.content
    end

    # Check for skipped
    skipped = testcase_node.at_xpath("skipped")
    if skipped
      status = "skipped"
      failure_message = skipped.attr("message") if skipped.attr("message")
    end

    # Get system output
    system_out_node = testcase_node.at_xpath("system-out")
    system_out = system_out_node.content if system_out_node

    system_err_node = testcase_node.at_xpath("system-err")
    system_err = system_err_node.content if system_err_node

    # Create test result
    test_results.create!(
      name: name,
      classname: classname,
      status: status,
      time: time,
      failure_message: failure_message,
      failure_type: failure_type,
      failure_stacktrace: failure_stacktrace,
      system_out: system_out,
      system_err: system_err
    )
  end
end
