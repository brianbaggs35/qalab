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
end
