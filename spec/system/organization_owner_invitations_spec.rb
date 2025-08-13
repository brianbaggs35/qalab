require 'rails_helper'

RSpec.describe "Organization Owner Invitations", type: :system do
  let(:admin_user) { create(:user, :confirmed, role: 'system_admin') }

  before do
    # Clean up any existing data
    User.where.not(id: admin_user.id).destroy_all
    Organization.destroy_all
    Invitation.destroy_all

    sign_in admin_user
  end

  describe "System admin inviting organization owner" do
    it "allows system admin to invite organization owner" do
      visit system_admin_users_path

      expect(page).to have_link("Invite Organization Owner")
      click_link "Invite Organization Owner"

      expect(page).to have_content("Invite Organization Owner")
      expect(page).to have_content("Send an invitation to create a new organization")

      fill_in "Email Address", with: "owner@newcompany.com"
      click_button "Send Invitation"

      expect(page).to have_content("Organization owner invitation sent to owner@newcompany.com successfully!")

      # Verify invitation was created
      invitation = Invitation.find_by(email: "owner@newcompany.com")
      expect(invitation).to be_present
      expect(invitation.role).to eq("organization_owner")
      expect(invitation.organization).to be_nil
      expect(invitation.invited_by).to eq(admin_user)
    end

    it "validates email address" do
      visit invite_organization_owner_system_admin_users_path

      fill_in "Email Address", with: "invalid-email"
      click_button "Send Invitation"

      expect(page).to have_content("Please provide a valid email address.")
    end

    it "prevents inviting existing users" do
      existing_user = create(:user, :confirmed, email: "existing@example.com")

      visit invite_organization_owner_system_admin_users_path

      fill_in "Email Address", with: "existing@example.com"
      click_button "Send Invitation"

      expect(page).to have_content("A user with this email address already exists")
    end
  end

  describe "Organization owner accepting invitation and onboarding" do
    let!(:invitation) do
      create(:invitation, :organization_owner,
             email: "newowner@example.com",
             invited_by: admin_user)
    end

    it "allows organization owner to register and complete onboarding" do
      visit accept_invitation_path(token: invitation.token)

      expect(page).to have_current_path(new_user_registration_path)
      expect(page).to have_field("Invitation Code", with: invitation.token)

      # Register account
      fill_in "First name", with: "John"
      fill_in "Last name", with: "Owner"
      fill_in "Email address", with: "newowner@example.com"
      fill_in "Password", with: "password123456"
      fill_in "Confirm password", with: "password123456"

      click_button "Create account"

      # Should go to onboarding (not dashboard like regular invitations)
      expect(page).to have_content("Welcome to QA Lab!")

      # Continue to organization creation
      click_link "Create Your Organization"

      expect(page).to have_content("Create Your Organization")

      # Create organization
      fill_in "Organization Name", with: "New Company Inc"
      click_button "Create Organization"

      # Should complete onboarding
      expect(page).to have_content("You're All Set!")
      expect(page).to have_content("Welcome to New Company Inc on QA Lab")

      # Verify everything was set up correctly
      user = User.find_by(email: "newowner@example.com")
      expect(user).to be_present
      expect(user.onboarding_completed?).to be true

      organization = Organization.find_by(name: "New Company Inc")
      expect(organization).to be_present
      expect(user.owner_of?(organization)).to be true

      # Verify invitation was accepted
      expect(invitation.reload.accepted?).to be true
    end
  end
end
