require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      invitation = create(:invitation)
      expect(invitation).to be_valid
    end

    it 'requires an email' do
      invitation = build(:invitation, email: nil)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include("can't be blank")
    end

    it 'validates email format' do
      invitation = build(:invitation, email: 'invalid_email')
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include('is invalid')
    end

    it 'validates role inclusion' do
      invitation = build(:invitation, role: 'invalid_role')
      expect(invitation).not_to be_valid
      expect(invitation.errors[:role]).to include('is not included in the list')
    end

    it 'generates a unique token before validation' do
      invitation = create(:invitation)
      expect(invitation.token).to be_present
      expect(invitation.token.length).to be > 20
    end
  end

  describe 'status methods' do
    it 'returns false for accepted? when not accepted' do
      invitation = build(:invitation)
      expect(invitation.accepted?).to be false
    end

    it 'returns true for accepted? when accepted' do
      invitation = build(:invitation, :accepted)
      expect(invitation.accepted?).to be true
    end

    it 'returns false for expired? when not expired' do
      invitation = build(:invitation)
      expect(invitation.expired?).to be false
    end

    it 'returns true for expired? when expired' do
      invitation = build(:invitation, :expired)
      expect(invitation.expired?).to be true
    end

    it 'returns true for valid_invitation? when not accepted and not expired' do
      invitation = build(:invitation)
      expect(invitation.valid_invitation?).to be true
    end

    it 'returns false for valid_invitation? when accepted' do
      invitation = build(:invitation, :accepted)
      expect(invitation.valid_invitation?).to be false
    end

    it 'returns false for valid_invitation? when expired' do
      invitation = build(:invitation, :expired)
      expect(invitation.valid_invitation?).to be false
    end
  end

  describe 'scopes' do
    let!(:pending_invitation) { create(:invitation) }
    let!(:accepted_invitation) { create(:invitation, :accepted) }
    let!(:expired_invitation) { create(:invitation, :expired) }

    it 'returns only pending invitations with pending scope' do
      expect(described_class.pending).to contain_exactly(pending_invitation, expired_invitation)
    end

    it 'returns only expired invitations with expired scope' do
      expect(described_class.expired).to contain_exactly(expired_invitation)
    end

    it 'returns only valid invitations with valid_invitations scope' do
      expect(described_class.valid_invitations).to contain_exactly(pending_invitation)
    end
  end

  describe 'class methods' do
    describe '.find_by_token' do
      it 'finds invitation by token' do
        invitation = create(:invitation, token: 'test_token_123')
        expect(described_class.find_by_token('test_token_123')).to eq(invitation)
      end

      it 'returns nil when token not found' do
        expect(described_class.find_by_token('nonexistent')).to be_nil
      end
    end

    describe '.find_valid_invitation' do
      it 'returns valid invitation by token' do
        invitation = create(:invitation, token: 'valid_token')
        expect(described_class.find_valid_invitation('valid_token')).to eq(invitation)
      end

      it 'returns nil for expired invitation' do
        invitation = create(:invitation, :expired, token: 'expired_token')
        expect(described_class.find_valid_invitation('expired_token')).to be_nil
      end

      it 'returns nil for accepted invitation' do
        invitation = create(:invitation, :accepted, token: 'accepted_token')
        expect(described_class.find_valid_invitation('accepted_token')).to be_nil
      end

      it 'returns nil for non-existent token' do
        expect(described_class.find_valid_invitation('nonexistent')).to be_nil
      end
    end
  end

  describe 'validations with existing users' do
    let(:existing_user) { create(:user, email: 'existing@example.com') }

    it 'prevents invitation to already registered email' do
      existing_user # Create the user first
      invitation = build(:invitation, email: 'existing@example.com')
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include('is already registered')
    end

    it 'prevents duplicate pending invitations for same email and organization' do
      organization = create(:organization)
      create(:invitation, email: 'test@example.com', organization: organization)

      duplicate = build(:invitation, email: 'test@example.com', organization: organization)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('has already been invited to this organization')
    end

    it 'allows invitation to different organization' do
      org1 = create(:organization)
      org2 = create(:organization)
      create(:invitation, email: 'test@example.com', organization: org1)

      invitation = build(:invitation, email: 'test@example.com', organization: org2)
      expect(invitation).to be_valid
    end
  end

  describe '#accept!' do
    it 'sets accepted_at timestamp for valid invitation' do
      invitation = create(:invitation)
      expect { invitation.accept! }.to change(invitation, :accepted_at).from(nil)
    end

    it 'does not set accepted_at for expired invitation' do
      invitation = create(:invitation, :expired)
      expect { invitation.accept! }.not_to change(invitation, :accepted_at)
    end
  end
end
