require 'rails_helper'

RSpec.describe "User Onboarding", type: :system do
  describe "First user registration and onboarding" do
    before do
      # Ensure no organizations exist (first user scenario)
      Organization.destroy_all
      User.destroy_all
    end

    it "allows first user to register without invitation and complete onboarding" do
      visit new_user_registration_path

      # Should show first user welcome message
      expect(page).to have_content("Welcome First User!")
      expect(page).not_to have_field("Invitation Code")

      # Fill in registration form
      fill_in "First name", with: "John"
      fill_in "Last name", with: "Doe"
      fill_in "Email address", with: "john@example.com"
      fill_in "Password", with: "password123456"
      fill_in "Confirm password", with: "password123456"

      click_button "Create account"

      # Should redirect to onboarding welcome
      expect(page).to have_content("Welcome to QA Lab!")
      expect(page).to have_content("John Doe")

      # Continue to organization creation
      click_link "Create Your Organization"

      expect(page).to have_content("Create Your Organization")
      expect(page).to have_content("Welcome First User!")

      # Create organization
      fill_in "Organization Name", with: "Test Company"
      click_button "Create Organization"

      # Should complete onboarding
      expect(page).to have_content("You're All Set!")
      expect(page).to have_content("Welcome to Test Company on QA Lab")

      # Verify user and organization were created properly
      user = User.find_by(email: "john@example.com")
      expect(user).to be_present
      expect(user.onboarding_completed?).to be true

      organization = Organization.find_by(name: "Test Company")
      expect(organization).to be_present
      expect(user.owner_of?(organization)).to be true
    end
  end

  describe "Subsequent user registration with invitation" do
    let!(:organization) { create(:organization, name: "Existing Org") }
    let!(:inviting_user) { create(:user, :confirmed) }
    let!(:invitation) do
      create(:invitation,
             email: "invited@example.com",
             organization: organization,
             invited_by: inviting_user,
             role: "member")
    end

    before do
      organization.organization_users.create!(user: inviting_user, role: "owner")
    end

    it "requires invitation for subsequent users" do
      visit new_user_registration_path

      # Should show invitation required message
      expect(page).to have_content("Invitation Required")
      expect(page).to have_field("Invitation Code")

      # Try to register without invitation code
      fill_in "First name", with: "Jane"
      fill_in "Last name", with: "Smith"
      fill_in "Email address", with: "jane@example.com"
      fill_in "Password", with: "password123456"
      fill_in "Confirm password", with: "password123456"

      click_button "Create account"

      # Should show error
      expect(page).to have_content("Sign ups are by invitation only")
    end

    it "allows registration with valid invitation token" do
      visit new_user_registration_path(invitation_token: invitation.token)

      expect(page).to have_field("Invitation Code", with: invitation.token)

      fill_in "First name", with: "Jane"
      fill_in "Last name", with: "Smith"
      fill_in "Email address", with: "invited@example.com"
      fill_in "Password", with: "password123456"
      fill_in "Confirm password", with: "password123456"

      click_button "Create account"

      # Should redirect directly to dashboard (no onboarding for invited users)
      expect(page).to have_content("Dashboard")

      # Verify user was added to organization
      user = User.find_by(email: "invited@example.com")
      expect(user).to be_present
      expect(user.organizations).to include(organization)
      expect(user.role_in_organization(organization)).to eq("member")
    end
  end
end
