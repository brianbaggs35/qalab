require 'rails_helper'

RSpec.describe TestResult, type: :model do
  describe "associations" do
    it { should belong_to(:test_run) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:status).in_array(%w[passed failed error skipped]) }
  end

  describe "scopes" do
    let!(:test_run) { create(:test_run) }
    let!(:passed_result) { create(:test_result, status: 'passed', test_run: test_run) }
    let!(:failed_result) { create(:test_result, status: 'failed', test_run: test_run) }
    let!(:error_result) { create(:test_result, status: 'error', test_run: test_run) }
    let!(:skipped_result) { create(:test_result, status: 'skipped', test_run: test_run) }

    it "returns passed results" do
      expect(TestResult.passed).to contain_exactly(passed_result)
    end

    it "returns failed results" do
      expect(TestResult.failed).to contain_exactly(failed_result)
    end

    it "returns error results" do
      expect(TestResult.error).to contain_exactly(error_result)
    end

    it "returns skipped results" do
      expect(TestResult.skipped).to contain_exactly(skipped_result)
    end

    it "filters by classname" do
      test_result = create(:test_result, classname: 'MyTest', test_run: test_run)
      create(:test_result, classname: 'OtherTest', test_run: test_run)
      
      expect(TestResult.by_class('MyTest')).to contain_exactly(test_result)
    end
  end

  describe "status helper methods" do
    let(:test_run) { create(:test_run) }
    
    it "returns true for passed? when status is passed" do
      result = build(:test_result, status: 'passed', test_run: test_run)
      expect(result.passed?).to be true
      expect(result.failed?).to be false
      expect(result.error?).to be false
      expect(result.skipped?).to be false
    end

    it "returns true for failed? when status is failed" do
      result = build(:test_result, status: 'failed', test_run: test_run)
      expect(result.passed?).to be false
      expect(result.failed?).to be true
      expect(result.error?).to be false
      expect(result.skipped?).to be false
    end

    it "returns true for error? when status is error" do
      result = build(:test_result, status: 'error', test_run: test_run)
      expect(result.passed?).to be false
      expect(result.failed?).to be false
      expect(result.error?).to be true
      expect(result.skipped?).to be false
    end

    it "returns true for skipped? when status is skipped" do
      result = build(:test_result, status: 'skipped', test_run: test_run)
      expect(result.passed?).to be false
      expect(result.failed?).to be false
      expect(result.error?).to be false
      expect(result.skipped?).to be true
    end
  end

  describe "#has_failure?" do
    let(:test_run) { create(:test_run) }

    it "returns true for failed status" do
      result = build(:test_result, status: 'failed', test_run: test_run)
      expect(result.has_failure?).to be true
    end

    it "returns true for error status" do
      result = build(:test_result, status: 'error', test_run: test_run)
      expect(result.has_failure?).to be true
    end

    it "returns false for passed status" do
      result = build(:test_result, status: 'passed', test_run: test_run)
      expect(result.has_failure?).to be false
    end

    it "returns false for skipped status" do
      result = build(:test_result, status: 'skipped', test_run: test_run)
      expect(result.has_failure?).to be false
    end
  end

  describe "#full_stacktrace" do
    let(:test_run) { create(:test_run) }

    it "returns nil when there's no failure" do
      result = build(:test_result, status: 'passed', test_run: test_run)
      expect(result.full_stacktrace).to be_nil
    end

    it "returns failure_stacktrace when present" do
      stacktrace = "Stack trace line 1\nStack trace line 2"
      result = build(:test_result, status: 'failed', failure_stacktrace: stacktrace, test_run: test_run)
      expect(result.full_stacktrace).to eq(stacktrace)
    end

    it "returns failure_message when stacktrace is blank" do
      message = "Test failed with assertion error"
      result = build(:test_result, status: 'failed', failure_message: message, failure_stacktrace: '', test_run: test_run)
      expect(result.full_stacktrace).to eq(message)
    end

    it "returns failure_message when stacktrace is nil" do
      message = "Test failed with assertion error"
      result = build(:test_result, status: 'failed', failure_message: message, failure_stacktrace: nil, test_run: test_run)
      expect(result.full_stacktrace).to eq(message)
    end

    it "returns nil when both stacktrace and message are blank" do
      result = build(:test_result, status: 'failed', failure_message: '', failure_stacktrace: '', test_run: test_run)
      expect(result.full_stacktrace).to be_nil
    end
  end
end
