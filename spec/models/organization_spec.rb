require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      organization = build(:organization, name: nil)
      expect(organization).not_to be_valid
      expect(organization.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      create(:organization, name: 'Test Organization')
      organization = build(:organization, name: 'Test Organization')
      expect(organization).not_to be_valid
      expect(organization.errors[:name]).to include("has already been taken")
    end
  end

  describe 'associations' do
    it 'has many organization_users' do
      expect(Organization.reflect_on_association(:organization_users).macro).to eq(:has_many)
    end

    it 'has many users through organization_users' do
      expect(Organization.reflect_on_association(:users).macro).to eq(:has_many)
    end

    it 'has many owners' do
      expect(Organization.reflect_on_association(:owners).macro).to eq(:has_many)
    end
  end

  describe 'serialization' do
    it 'serializes settings as JSON' do
      organization = create(:organization, settings: { theme: 'dark', notifications: true })
      organization.reload
      expect(organization.settings).to eq({ 'theme' => 'dark', 'notifications' => true })
    end
  end

  describe '#success_rate' do
    let(:organization) { create(:organization) }
    let(:user) { create(:user) }

    context 'with no test runs' do
      it 'returns 0' do
        expect(organization.success_rate).to eq(0)
      end
    end

    context 'with no completed test runs' do
      it 'returns 0' do
        create(:test_run, organization: organization, user: user, status: 'pending')
        expect(organization.success_rate).to eq(0)
      end
    end

    context 'with completed test runs' do
      it 'calculates success rate correctly' do
        # Test run with 80% success rate (8/10 passed)
        create(:test_run, :completed, 
               organization: organization, 
               user: user,
               results_summary: {
                 'total_tests' => 10,
                 'passed' => 8,
                 'failed' => 2,
                 'skipped' => 0
               })
        
        # Test run with 100% success rate (5/5 passed)
        create(:test_run, :completed,
               organization: organization,
               user: user,
               results_summary: {
                 'total_tests' => 5,
                 'passed' => 5,
                 'failed' => 0,
                 'skipped' => 0
               })
        
        # Overall: 13/15 = 86.67%
        expect(organization.success_rate).to eq(86.67)
      end
    end

    context 'with zero total tests' do
      it 'returns 0' do
        create(:test_run, :completed,
               organization: organization,
               user: user,
               results_summary: {
                 'total_tests' => 0,
                 'passed' => 0,
                 'failed' => 0,
                 'skipped' => 0
               })
        
        expect(organization.success_rate).to eq(0)
      end
    end
  end
end
