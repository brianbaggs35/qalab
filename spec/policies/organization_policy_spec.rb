require 'rails_helper'

RSpec.describe OrganizationPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }
  let(:organization) { create(:organization) }
  let(:organization_user) { create(:organization_user, organization: organization, user: user, role: 'member') }

  describe 'Scope' do
    it 'returns all organizations for system admin' do
      scope = Pundit.policy_scope(system_admin, Organization)
      expect(scope).to eq(Organization.all)
    end

    it 'returns only user organizations for regular users' do
      organization_user # create the association
      scope = Pundit.policy_scope(user, Organization)
      expect(scope).to include(organization)
    end
  end

  describe 'permissions' do
    context 'for system admin' do
      it 'allows all actions' do
        expect(subject.new(system_admin, organization)).to be_index
        expect(subject.new(system_admin, organization)).to be_show
        expect(subject.new(system_admin, organization)).to be_create
        expect(subject.new(system_admin, organization)).to be_update
        expect(subject.new(system_admin, organization)).to be_destroy
      end
    end

    context 'for organization owner' do
      let(:owner) { create(:user) }
      let(:owner_org_user) { create(:organization_user, organization: organization, user: owner, role: 'owner') }

      it 'allows management actions' do
        owner_org_user
        expect(subject.new(owner, organization)).to be_show
        expect(subject.new(owner, organization)).to be_update
        expect(subject.new(owner, organization)).to be_destroy
        expect(subject.new(owner, organization)).to be_manage_users
        expect(subject.new(owner, organization)).to be_invite_users
      end
    end

    context 'for organization member' do
      it 'allows limited actions' do
        organization_user
        expect(subject.new(user, organization)).to be_show
        expect(subject.new(user, organization)).not_to be_update
        expect(subject.new(user, organization)).not_to be_destroy
        expect(subject.new(user, organization)).not_to be_manage_users
      end
    end
  end
end
