require 'rails_helper'

RSpec.describe OrganizationUser, type: :model do
  describe 'validations' do
    it 'validates inclusion of role' do
      org_user = build(:organization_user, role: 'invalid_role')
      expect(org_user).not_to be_valid
      expect(org_user.errors[:role]).to include("is not included in the list")
    end

    it 'validates uniqueness of user per organization' do
      organization = create(:organization)
      user = create(:user)
      create(:organization_user, organization: organization, user: user)
      
      duplicate = build(:organization_user, organization: organization, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("has already been taken")
    end
  end

  describe 'associations' do
    it 'belongs to organization' do
      expect(OrganizationUser.reflect_on_association(:organization).macro).to eq(:belongs_to)
    end

    it 'belongs to user' do
      expect(OrganizationUser.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'scopes' do
    let(:organization) { create(:organization) }
    let!(:owner) { create(:organization_user, :owner, organization: organization) }
    let!(:admin) { create(:organization_user, :admin, organization: organization) }
    let!(:member) { create(:organization_user, organization: organization, role: 'member') }

    it 'returns owners' do
      expect(OrganizationUser.owners).to include(owner)
      expect(OrganizationUser.owners).not_to include(admin, member)
    end

    it 'returns admins' do
      expect(OrganizationUser.admins).to include(admin)
      expect(OrganizationUser.admins).not_to include(owner, member)
    end

    it 'returns members' do
      expect(OrganizationUser.members).to include(member)
      expect(OrganizationUser.members).not_to include(owner, admin)
    end

    it 'returns managers (owners and admins)' do
      expect(OrganizationUser.managers).to include(owner, admin)
      expect(OrganizationUser.managers).not_to include(member)
    end
  end

  describe 'role methods' do
    it 'correctly identifies owner' do
      owner = create(:organization_user, :owner)
      expect(owner.owner?).to be true
      expect(owner.admin?).to be false
      expect(owner.manager?).to be true
    end

    it 'correctly identifies admin' do
      admin = create(:organization_user, :admin)
      expect(admin.owner?).to be false
      expect(admin.admin?).to be true
      expect(admin.manager?).to be true
    end

    it 'correctly identifies member' do
      member = create(:organization_user, role: 'member')
      expect(member.owner?).to be false
      expect(member.admin?).to be false
      expect(member.manager?).to be false
    end
  end
end
