require 'rails_helper'

RSpec.describe "Organization Owner Invitations", type: :request do
  let(:admin_user) { create(:user, :confirmed, role: 'system_admin') }

  before do
    # Clean up any existing data
    User.where.not(id: admin_user.id).destroy_all
    Organization.destroy_all
    Invitation.destroy_all
  end

  describe "System admin inviting organization owner" do
    before do
      sign_in admin_user
    end

    it "validates email address" do
      post send_organization_owner_invitation_system_admin_users_path, params: { email: 'invalid-email' }

      expect(response).to redirect_to(invite_organization_owner_system_admin_users_path)
      follow_redirect!
      expect(flash[:alert]).to eq('Please provide a valid email address.')
    end

    it "prevents inviting existing users" do
      existing_user = create(:user, :confirmed, email: "existing@example.com")

      post send_organization_owner_invitation_system_admin_users_path, params: { email: "existing@example.com" }

      expect(response).to redirect_to(invite_organization_owner_system_admin_users_path)
      follow_redirect!
      expect(flash[:alert]).to eq('A user with this email address already exists.')
    end

    it "allows system admin to invite organization owner" do
      expect {
        post send_organization_owner_invitation_system_admin_users_path, params: { email: "owner@newcompany.com" }
      }.to change(Invitation, :count).by(1)

      invitation = Invitation.find_by(email: "owner@newcompany.com")
      expect(invitation).to be_present
      expect(invitation.role).to eq("organization_owner")
      expect(invitation.organization).to be_nil
      expect(invitation.invited_by).to eq(admin_user)

      expect(response).to redirect_to(system_admin_users_path)
      follow_redirect!
      expect(flash[:notice]).to include("invitation sent to owner@newcompany.com successfully")
    end
  end

  describe "Organization owner accepting invitation and onboarding" do
    let!(:invitation) do
      create(:invitation, :organization_owner,
             email: "newowner@example.com",
             invited_by: admin_user)
    end

    it "redirects to registration when not signed in" do
      get accept_invitation_path(token: invitation.token)

      expect(response).to redirect_to(new_user_registration_path(invitation_token: invitation.token))
    end

    it "handles registration with invitation token" do
      user_params = {
        user: {
          first_name: "John",
          last_name: "Owner",
          email: "newowner@example.com",
          password: "password123456",
          password_confirmation: "password123456",
          invitation_token: invitation.token
        }
      }

      expect {
        post user_registration_path, params: user_params
      }.to change(User, :count).by(1)

      user = User.find_by(email: "newowner@example.com")
      expect(user).to be_present
      expect(response).to redirect_to(onboarding_welcome_path)

      # Verify invitation was accepted
      expect(invitation.reload.accepted?).to be true
    end
  end
end
