require 'rails_helper'

RSpec.describe TestSuite, type: :model do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  describe 'validations' do
    subject { build(:test_suite, user: user, organization: organization) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(100) }
    it { should validate_length_of(:description).is_at_most(500) }

    it 'validates uniqueness of name scoped to organization' do
      create(:test_suite, name: 'Unique Suite', organization: organization, user: user)
      test_suite = build(:test_suite, name: 'Unique Suite', organization: organization, user: user)
      expect(test_suite).not_to be_valid
      expect(test_suite.errors[:name]).to include('has already been taken')
    end

    it 'allows same name in different organizations' do
      other_org = create(:organization, name: 'Other Org')
      create(:test_suite, name: 'Same Name', organization: organization, user: user)
      test_suite = build(:test_suite, name: 'Same Name', organization: other_org, user: user)
      expect(test_suite).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:organization) }
    it { should have_many(:test_cases).dependent(:nullify) }
  end

  describe 'scopes' do
    let!(:test_suite1) { create(:test_suite, organization: organization, user: user) }
    let!(:test_suite2) { create(:test_suite, organization: organization, user: user) }
    let!(:other_org_suite) { create(:test_suite, user: user) }

    it 'filters by organization' do
      expect(TestSuite.for_organization(organization)).to include(test_suite1, test_suite2)
      expect(TestSuite.for_organization(organization)).not_to include(other_org_suite)
    end

    it 'orders by recent' do
      sleep 0.01 # Ensure different timestamps
      newer_suite = create(:test_suite, organization: organization, user: user)
      expect(TestSuite.recent.pluck(:id).first).to eq(newer_suite.id)
    end
  end

  describe 'counter methods' do
    let(:test_suite) { create(:test_suite, user: user, organization: organization) }

    context 'with test cases' do
      before do
        create(:test_case, :ready, test_suite: test_suite, organization: organization, user: user)
        create(:test_case, :approved, test_suite: test_suite, organization: organization, user: user)
        create(:test_case, test_suite: test_suite, organization: organization, user: user) # draft by default
        create(:test_case, test_suite: test_suite, organization: organization, user: user) # draft by default
      end

      it 'counts total test cases' do
        expect(test_suite.test_cases_count).to eq(4)
      end

      it 'counts draft test cases' do
        expect(test_suite.draft_test_cases_count).to eq(2)
      end

      it 'counts ready test cases' do
        expect(test_suite.ready_test_cases_count).to eq(1)
      end

      it 'counts approved test cases' do
        expect(test_suite.approved_test_cases_count).to eq(1)
      end
    end

    context 'without test cases' do
      it 'returns zero for all counts' do
        expect(test_suite.test_cases_count).to eq(0)
        expect(test_suite.draft_test_cases_count).to eq(0)
        expect(test_suite.ready_test_cases_count).to eq(0)
        expect(test_suite.approved_test_cases_count).to eq(0)
      end
    end
  end

  describe 'test case nullification on destroy' do
    let(:test_suite) { create(:test_suite, user: user, organization: organization) }
    
    it 'nullifies test_suite_id when test suite is destroyed' do
      test_case = create(:test_case, test_suite: test_suite, organization: organization, user: user)
      expect(test_case.test_suite_id).to eq(test_suite.id)
      
      test_suite.destroy
      test_case.reload
      expect(test_case.test_suite_id).to be_nil
    end
  end
end
