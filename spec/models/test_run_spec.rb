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
        # Mock update! to raise an error during processing
        allow(test_run).to receive(:update!).with(status: 'processing').and_call_original
        allow(test_run).to receive(:update!).with(hash_including(status: 'completed')).and_raise(StandardError, 'Processing failed')
        allow(test_run).to receive(:update!).with(hash_including(status: 'failed')).and_call_original

        test_run.process_xml_file
        test_run.reload
        expect(test_run.status).to eq('failed')
        expect(test_run.results_summary['error']).to include('Processing failed')
      end

      it 'returns false on error' do
        # Mock update! to raise an error during processing
        allow(test_run).to receive(:update!).with(status: 'processing').and_call_original
        allow(test_run).to receive(:update!).with(hash_including(status: 'completed')).and_raise(StandardError, 'Processing failed')
        allow(test_run).to receive(:update!).with(hash_including(status: 'failed')).and_call_original

        expect(test_run.process_xml_file).to be false
      end
    end
  end
end
