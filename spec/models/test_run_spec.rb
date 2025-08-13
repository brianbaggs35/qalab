require 'rails_helper'

RSpec.describe TestRun, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:test_run) { build(:test_run, organization: organization, user: user) }

  describe 'validations' do
    it 'validates presence of name' do
      test_run.name = nil
      expect(test_run).not_to be_valid
      expect(test_run.errors[:name]).to include("can't be blank")
    end

    it 'validates inclusion of status' do
      test_run.status = 'invalid_status'
      expect(test_run).not_to be_valid
      expect(test_run.errors[:status]).to include("is not included in the list")
    end

    it 'accepts valid statuses' do
      TestRun::VALID_STATUSES.each do |status|
        test_run.status = status
        expect(test_run).to be_valid
      end
    end
  end

  describe 'associations' do
    it 'belongs to organization' do
      expect(test_run.organization).to eq(organization)
    end

    it 'belongs to user' do
      expect(test_run.user).to eq(user)
    end
  end

  describe 'scopes' do
    let!(:test_run1) { create(:test_run, organization: organization, user: user, status: 'completed', environment: 'production') }
    let!(:test_run2) { create(:test_run, organization: organization, user: user, status: 'failed', environment: 'staging') }

    describe '.for_organization' do
      it 'returns test runs for specific organization' do
        expect(TestRun.for_organization(organization)).to include(test_run1, test_run2)
      end
    end

    describe '.by_status' do
      it 'returns test runs with specific status' do
        expect(TestRun.by_status('completed')).to include(test_run1)
        expect(TestRun.by_status('completed')).not_to include(test_run2)
      end
    end

    describe '.by_environment' do
      it 'returns test runs for specific environment' do
        expect(TestRun.by_environment('production')).to include(test_run1)
        expect(TestRun.by_environment('production')).not_to include(test_run2)
      end
    end

    describe '.recent' do
      it 'returns test runs ordered by created_at desc' do
        expect(TestRun.recent.first).to eq(test_run2)
      end
    end
  end

  describe 'status methods' do
    it 'correctly identifies pending status' do
      test_run.status = 'pending'
      expect(test_run.pending?).to be true
      expect(test_run.processing?).to be false
    end

    it 'correctly identifies processing status' do
      test_run.status = 'processing'
      expect(test_run.processing?).to be true
      expect(test_run.completed?).to be false
    end

    it 'correctly identifies completed status' do
      test_run.status = 'completed'
      expect(test_run.completed?).to be true
      expect(test_run.failed?).to be false
    end

    it 'correctly identifies failed status' do
      test_run.status = 'failed'
      expect(test_run.failed?).to be true
      expect(test_run.pending?).to be false
    end
  end

  describe 'results summary helpers' do
    before do
      test_run.results_summary = {
        'total_tests' => 100,
        'passed' => 85,
        'failed' => 10,
        'skipped' => 5
      }
    end

    it 'returns correct total tests' do
      expect(test_run.total_tests).to eq(100)
    end

    it 'returns correct passed tests' do
      expect(test_run.passed_tests).to eq(85)
    end

    it 'returns correct failed tests' do
      expect(test_run.failed_tests).to eq(10)
    end

    it 'returns correct skipped tests' do
      expect(test_run.skipped_tests).to eq(5)
    end

    it 'calculates correct success rate' do
      expect(test_run.success_rate).to eq(85.0)
    end

    it 'returns 0 success rate when no tests' do
      test_run.results_summary = {}
      expect(test_run.success_rate).to eq(0)
    end
  end

  describe '#process_xml_file' do
    context 'with valid xml_file' do
      before do
        test_run.xml_file = '<testsuites><testsuite name="Test" tests="10" failures="2" skipped="1" time="5.5"></testsuite></testsuites>'
        test_run.save!
      end

      it 'processes the XML file and updates status' do
        expect { test_run.process_xml_file }.to change { test_run.reload.status }.from('pending').to('completed')
      end

      it 'updates results summary' do
        test_run.process_xml_file
        test_run.reload
        expect(test_run.results_summary['total_tests']).to be_present
        expect(test_run.results_summary['passed']).to be_present
      end

      it 'returns true on successful processing' do
        expect(test_run.process_xml_file).to be true
      end
    end

    context 'without xml_file' do
      before do
        test_run.xml_file = nil
        test_run.save!
      end

      it 'returns false when no XML file present' do
        expect(test_run.process_xml_file).to be false
      end

      it 'does not change status' do
        expect { test_run.process_xml_file }.not_to change { test_run.reload.status }
      end
    end

    context 'when processing fails' do
      before do
        test_run.xml_file = 'invalid xml'
        test_run.save!
      end

      it 'sets status to failed on error' do
        # Use valid XML that will be detected but then fail during processing
        test_run.xml_file = '<testsuites><testsuite name="Test" tests="1"></testsuite></testsuites>'
        test_run.save!
        
        # Mock the parsing method to raise an error
        allow(test_run).to receive(:parse_junit_xml).and_raise(StandardError, 'Processing failed')

        test_run.process_xml_file
        test_run.reload
        expect(test_run.status).to eq('failed')
        expect(test_run.results_summary['error']).to include('Processing failed')
      end

      it 'returns false on error' do
        # Use valid XML that will be detected but then fail during processing  
        test_run.xml_file = '<testsuites><testsuite name="Test" tests="1"></testsuite></testsuites>'
        test_run.save!
        
        # Mock the parsing method to raise an error
        allow(test_run).to receive(:parse_junit_xml).and_raise(StandardError, 'Processing failed')

        expect(test_run.process_xml_file).to be false
      end
    end

    context 'with TestNG XML format' do
      let(:testng_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <testng-results total="3" passed="1" failed="1" skipped="1">
            <suite name="SampleTestSuite" duration-ms="2500" started-at="2023-08-13T12:00:00Z" finished-at="2023-08-13T12:00:02Z">
              <test name="SampleTest" duration-ms="2500" started-at="2023-08-13T12:00:00Z" finished-at="2023-08-13T12:00:02Z">
                <class name="com.example.SampleTest">
                  <test-method name="testSuccess" status="PASS" duration-ms="500" started-at="2023-08-13T12:00:00Z" finished-at="2023-08-13T12:00:00Z" is-config="false">
                  </test-method>
                  <test-method name="testFailure" status="FAIL" duration-ms="1000" started-at="2023-08-13T12:00:01Z" finished-at="2023-08-13T12:00:02Z" is-config="false">
                    <exception class="java.lang.AssertionError" message="Test failed">
                      <full-stacktrace>java.lang.AssertionError: Test failed
                at com.example.SampleTest.testFailure(SampleTest.java:42)</full-stacktrace>
                    </exception>
                  </test-method>
                  <test-method name="testSkipped" status="SKIP" duration-ms="0" started-at="2023-08-13T12:00:02Z" finished-at="2023-08-13T12:00:02Z" is-config="false">
                  </test-method>
                </class>
              </test>
            </suite>
          </testng-results>
        XML
      end

      before do
        test_run.xml_file = testng_xml
        test_run.save!
      end

      it 'processes TestNG XML successfully' do
        expect { test_run.process_xml_file }.to change { test_run.reload.status }.from('pending').to('completed')
      end

      it 'creates correct test results for TestNG format' do
        test_run.process_xml_file
        test_run.reload

        expect(test_run.test_results.count).to eq(3)
        
        success_result = test_run.test_results.find_by(name: 'testSuccess')
        expect(success_result).to be_present
        expect(success_result.status).to eq('passed')
        expect(success_result.classname).to eq('com.example.SampleTest')
        expect(success_result.time).to eq(0.5)
        
        failure_result = test_run.test_results.find_by(name: 'testFailure')
        expect(failure_result).to be_present
        expect(failure_result.status).to eq('failed')
        expect(failure_result.failure_message).to eq('Test failed')
        expect(failure_result.failure_type).to eq('java.lang.AssertionError')
        expect(failure_result.failure_stacktrace).to include('java.lang.AssertionError: Test failed')
        
        skipped_result = test_run.test_results.find_by(name: 'testSkipped')
        expect(skipped_result).to be_present
        expect(skipped_result.status).to eq('skipped')
      end

      it 'calculates correct summary statistics for TestNG' do
        test_run.process_xml_file
        test_run.reload

        summary = test_run.results_summary
        expect(summary['total_tests']).to eq(3)
        expect(summary['passed']).to eq(1)
        expect(summary['failed']).to eq(1)
        expect(summary['errors']).to eq(0) # TestNG doesn't separate errors from failures
        expect(summary['skipped']).to eq(1)
        expect(summary['format']).to eq('TestNG')
      end
    end

    context 'with JUnit XML format' do
      let(:junit_xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <testsuite tests="4" failures="1" errors="1" skipped="1" time="10.5" name="com.example.TestSuite">
            <testcase classname="com.example.TestClass" name="testPass" time="2.1">
            </testcase>
            <testcase classname="com.example.TestClass" name="testFail" time="3.2">
              <failure message="AssertionError: Expected 5 but was 4" type="AssertionError">
                java.lang.AssertionError: Expected 5 but was 4
                at com.example.TestClass.testFail(TestClass.java:42)
              </failure>
            </testcase>
            <testcase classname="com.example.TestClass" name="testError" time="1.8">
              <error message="NullPointerException" type="NullPointerException">
                java.lang.NullPointerException
                at com.example.TestClass.testError(TestClass.java:55)
              </error>
            </testcase>
            <testcase classname="com.example.TestClass" name="testSkip" time="0.0">
              <skipped message="Test skipped"></skipped>
            </testcase>
          </testsuite>
        XML
      end

      before do
        test_run.xml_file = junit_xml
        test_run.save!
      end

      it 'processes JUnit XML successfully' do
        expect { test_run.process_xml_file }.to change { test_run.reload.status }.from('pending').to('completed')
      end

      it 'creates correct test results for JUnit format' do
        test_run.process_xml_file
        test_run.reload

        expect(test_run.test_results.count).to eq(4)
        
        pass_result = test_run.test_results.find_by(name: 'testPass')
        expect(pass_result).to be_present
        expect(pass_result.status).to eq('passed')
        
        fail_result = test_run.test_results.find_by(name: 'testFail')
        expect(fail_result).to be_present
        expect(fail_result.status).to eq('failed')
        expect(fail_result.failure_message).to include('Expected 5 but was 4')
        
        error_result = test_run.test_results.find_by(name: 'testError')
        expect(error_result).to be_present
        expect(error_result.status).to eq('error')
        expect(error_result.failure_type).to eq('NullPointerException')
        
        skip_result = test_run.test_results.find_by(name: 'testSkip')
        expect(skip_result).to be_present
        expect(skip_result.status).to eq('skipped')
      end

      it 'calculates correct summary statistics for JUnit' do
        test_run.process_xml_file
        test_run.reload

        summary = test_run.results_summary
        expect(summary['total_tests']).to eq(4)
        expect(summary['passed']).to eq(1) # 4 total - 1 failed - 1 error - 1 skipped = 1 passed
        expect(summary['failed']).to eq(1)
        expect(summary['errors']).to eq(1)
        expect(summary['skipped']).to eq(1)
        expect(summary['format']).to eq('JUnit')
      end
    end

    context 'format detection' do
      it 'detects JUnit format correctly' do
        junit_xml = '<testsuites><testsuite name="Test" tests="1"></testsuite></testsuites>'
        test_run.xml_file = junit_xml
        test_run.save!
        
        expect(test_run.process_xml_file).to be true
        expect(test_run.reload.results_summary['format']).to eq('JUnit')
      end

      it 'detects TestNG format correctly' do
        testng_xml = '<testng-results><suite name="Test"><test name="TestSuite"><class name="TestClass"></class></test></suite></testng-results>'
        test_run.xml_file = testng_xml
        test_run.save!
        
        expect(test_run.process_xml_file).to be true
        expect(test_run.reload.results_summary['format']).to eq('TestNG')
      end

      it 'handles unsupported format gracefully' do
        unsupported_xml = '<some-other-format><test>data</test></some-other-format>'
        test_run.xml_file = unsupported_xml
        test_run.save!
        
        expect(test_run.process_xml_file).to be false
        expect(test_run.reload.status).to eq('failed')
        expect(test_run.results_summary['error']).to include('Unsupported XML format')
      end
    end
  end
end
