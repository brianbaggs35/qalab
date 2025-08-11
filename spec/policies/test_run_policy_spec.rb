require 'rails_helper'

RSpec.describe TestRunPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:system_admin) { create(:user, role: 'system_admin') }

  let!(:org_user) { create(:organization_user, organization: organization, user: user, role: 'member') }
  let!(:owner_user) { create(:user) }
  let!(:org_owner) { create(:organization_user, organization: organization, user: owner_user, role: 'owner') }

  let(:test_run) { create(:test_run, organization: organization, user: user) }
  let(:other_test_run) { create(:test_run, organization: other_organization, user: other_user) }

  describe 'Scope' do
    let!(:user_test_run) { create(:test_run, organization: organization, user: user) }
    let!(:other_org_test_run) { create(:test_run, organization: other_organization, user: other_user) }

    context 'for system admin' do
      it 'returns all test runs' do
        scope = Pundit.policy_scope(system_admin, TestRun)
        expect(scope).to include(user_test_run, other_org_test_run)
      end
    end

    context 'for regular user' do
      it 'returns only test runs from user organizations' do
        scope = Pundit.policy_scope(user, TestRun)
        expect(scope).to include(user_test_run)
        expect(scope).not_to include(other_org_test_run)
      end
    end
  end

  describe '#index?' do
    it 'grants access to regular users' do
      policy = TestRunPolicy.new(user, TestRun)
      expect(policy.index?).to be true
    end

    it 'denies access to system admins' do
      policy = TestRunPolicy.new(system_admin, TestRun)
      expect(policy.index?).to be false
    end
  end

  describe '#show?' do
    it 'grants access to users in the same organization' do
      policy = TestRunPolicy.new(user, test_run)
      expect(policy.show?).to be true
    end

    it 'denies access to users from different organizations' do
      policy = TestRunPolicy.new(other_user, test_run)
      expect(policy.show?).to be false
    end

    it 'denies access to system admins' do
      policy = TestRunPolicy.new(system_admin, test_run)
      expect(policy.show?).to be false
    end
  end

  describe '#create?' do
    it 'grants access to regular users' do
      policy = TestRunPolicy.new(user, TestRun)
      expect(policy.create?).to be true
    end

    it 'denies access to system admins' do
      policy = TestRunPolicy.new(system_admin, TestRun)
      expect(policy.create?).to be false
    end
  end

  describe '#update?' do
    context 'when user owns the test run' do
      it 'grants access' do
        policy = TestRunPolicy.new(user, test_run)
        expect(policy.update?).to be true
      end
    end

    context 'when user is organization owner/admin' do
      it 'grants access to organization owners' do
        policy = TestRunPolicy.new(owner_user, test_run)
        expect(policy.update?).to be true
      end
    end

    context 'when user is not owner and not org admin' do
      it 'denies access' do
        policy = TestRunPolicy.new(other_user, test_run)
        expect(policy.update?).to be false
      end
    end

    it 'denies access to system admins' do
      policy = TestRunPolicy.new(system_admin, test_run)
      expect(policy.update?).to be false
    end
  end

  describe '#destroy?' do
    context 'when user owns the test run' do
      it 'grants access' do
        policy = TestRunPolicy.new(user, test_run)
        expect(policy.destroy?).to be true
      end
    end

    context 'when user is organization owner/admin' do
      it 'grants access to organization owners' do
        policy = TestRunPolicy.new(owner_user, test_run)
        expect(policy.destroy?).to be true
      end
    end

    context 'when user is not owner and not org admin' do
      it 'denies access' do
        policy = TestRunPolicy.new(other_user, test_run)
        expect(policy.destroy?).to be false
      end
    end

    it 'denies access to system admins' do
      policy = TestRunPolicy.new(system_admin, test_run)
      expect(policy.destroy?).to be false
    end
  end
end
