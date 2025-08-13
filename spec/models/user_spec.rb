require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'validates presence of first_name' do
      user = build(:user, first_name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("can't be blank")
    end

    it 'validates presence of last_name' do
      user = build(:user, last_name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include("can't be blank")
    end

    it 'validates inclusion of role' do
      user = build(:user, role: 'invalid_role')
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("is not included in the list")
    end

    it 'accepts valid roles' do
      expect(build(:user, role: 'member')).to be_valid
      expect(build(:user, role: 'system_admin')).to be_valid
    end
  end

  describe 'associations' do
    it 'has many organization_users' do
      expect(User.reflect_on_association(:organization_users).macro).to eq(:has_many)
    end

    it 'has many organizations through organization_users' do
      expect(User.reflect_on_association(:organizations).macro).to eq(:has_many)
    end
  end

  describe 'scopes' do
    let!(:system_admin) { create(:user, :system_admin) }
    let!(:regular_user) { create(:user, role: 'member') }

    it 'returns system admins' do
      expect(User.system_admins).to include(system_admin)
      expect(User.system_admins).not_to include(regular_user)
    end

    it 'returns regular users' do
      expect(User.regular_users).to include(regular_user)
      expect(User.regular_users).not_to include(system_admin)
    end
  end

  describe 'methods' do
    let(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    describe '#full_name' do
      it 'returns concatenated first and last name' do
        expect(user.full_name).to eq('John Doe')
      end
    end

    describe '#system_admin?' do
      it 'returns true for system admin' do
        system_admin = create(:user, :system_admin)
        expect(system_admin.system_admin?).to be true
      end

      it 'returns false for regular user' do
        expect(user.system_admin?).to be false
      end
    end

    describe 'organization role methods' do
      let(:organization) { create(:organization) }
      let(:owner_user) { create(:user) }
      let(:admin_user) { create(:user) }
      let(:member_user) { create(:user) }

      before do
        create(:organization_user, :owner, organization: organization, user: owner_user)
        create(:organization_user, :admin, organization: organization, user: admin_user)
        create(:organization_user, organization: organization, user: member_user, role: 'member')
      end

      it '#role_in_organization returns correct role' do
        expect(owner_user.role_in_organization(organization)).to eq('owner')
        expect(admin_user.role_in_organization(organization)).to eq('admin')
        expect(member_user.role_in_organization(organization)).to eq('member')
      end

      it '#owner_of? returns correct value' do
        expect(owner_user.owner_of?(organization)).to be true
        expect(admin_user.owner_of?(organization)).to be false
        expect(member_user.owner_of?(organization)).to be false
      end

      it '#admin_of? returns correct value' do
        expect(owner_user.admin_of?(organization)).to be false
        expect(admin_user.admin_of?(organization)).to be true
        expect(member_user.admin_of?(organization)).to be false
      end

      it '#can_manage? returns correct value' do
        expect(owner_user.can_manage?(organization)).to be true
        expect(admin_user.can_manage?(organization)).to be true
        expect(member_user.can_manage?(organization)).to be false
      end
    end

    describe 'onboarding methods' do
      let(:user) { create(:user) }
      let(:organization) { create(:organization) }

      describe '#onboarding_completed?' do
        it 'returns true when onboarding_completed_at is present' do
          user.update!(onboarding_completed_at: Time.current)
          expect(user.onboarding_completed?).to be true
        end

        it 'returns false when onboarding_completed_at is nil' do
          user.update!(onboarding_completed_at: nil)
          expect(user.onboarding_completed?).to be false
        end
      end

      describe '#needs_onboarding?' do
        it 'returns true when onboarding not completed and no organizations' do
          user.update!(onboarding_completed_at: nil)
          expect(user.needs_onboarding?).to be true
        end

        it 'returns false when onboarding is completed' do
          user.update!(onboarding_completed_at: Time.current)
          expect(user.needs_onboarding?).to be false
        end

        it 'returns false when user belongs to an organization' do
          user.update!(onboarding_completed_at: nil)
          create(:organization_user, user: user, organization: organization)
          expect(user.needs_onboarding?).to be false
        end

        it 'returns false for system admins' do
          system_admin = create(:user, :system_admin)
          system_admin.update!(onboarding_completed_at: nil)
          expect(system_admin.needs_onboarding?).to be false
        end

        it 'returns true when user has accepted organization owner invitation' do
          user.update!(onboarding_completed_at: nil)
          invitation = create(:invitation, :organization_owner)
          user.accepted_organization_owner_invitation = invitation
          expect(user.needs_onboarding?).to be true
        end
      end
    end
  end
end
