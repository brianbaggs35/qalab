require 'rails_helper'

RSpec.describe "Organization Owner Invitations", type: :system do
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

    it "prevents inviting existing users" do
      existing_user = create(:user, :confirmed, email: "existing@example.com")

      visit invite_organization_owner_system_admin_users_path

      fill_in "Email Address", with: "existing@example.com"
      click_button "Send Invitation"

      # The flash message should be visible in the page
      within('[data-controller="alert"]', wait: 5) do
        expect(page).to have_content("A user with this email address already exists")
      end
    end
  end
end
