require 'rails_helper'

RSpec.describe Organization, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }

  describe 'callbacks' do
    it 'calls create_owner_relationship after create' do
      new_org = build(:organization)
      expect(new_org).to receive(:create_owner_relationship)
      new_org.save!
    end
  end

  describe '#success_rate' do
    context 'with no test runs' do
      it 'returns 0' do
        expect(organization.success_rate).to eq(0)
      end
    end

    context 'with test runs but no tests' do
      before do
        allow_any_instance_of(TestRun).to receive(:total_tests).and_return(0)
        allow_any_instance_of(TestRun).to receive(:passed_tests).and_return(0)
        create(:test_run, organization: organization, status: 'completed')
      end

      it 'returns 0' do
        expect(organization.success_rate).to eq(0)
      end
    end
  end
end
