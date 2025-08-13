require 'rails_helper'

RSpec.describe TestCase, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:test_case) { create(:test_case, organization: organization, user: user) }

  describe 'validations' do
    it 'requires title' do
      test_case.title = nil
      expect(test_case).not_to be_valid
      expect(test_case.errors[:title]).to include("can't be blank")
    end

    it 'requires description' do
      test_case.description = nil
      expect(test_case).not_to be_valid
      expect(test_case.errors[:description]).to include("can't be blank")
    end
  end

  describe 'enums' do
    it 'validates priority enum' do
      expect(test_case).to respond_to(:priority)
      test_case.priority = :high
      expect(test_case.priority).to eq('high')
    end

    it 'validates status enum' do
      expect(test_case).to respond_to(:status)
      test_case.status = :active
      expect(test_case.status).to eq('active')
    end
  end

  describe 'scopes' do
    let!(:active_case) { create(:test_case, status: :active) }
    let!(:draft_case) { create(:test_case, status: :draft) }

    it 'filters by status' do
      expect(TestCase.active).to include(active_case)
      expect(TestCase.active).not_to include(draft_case)
    end
  end

  describe 'callbacks' do
    it 'sets default status' do
      new_case = TestCase.new(title: 'Test', description: 'Desc', organization: organization, user: user)
      new_case.save!
      expect(new_case.status).to be_present
    end
  end
end