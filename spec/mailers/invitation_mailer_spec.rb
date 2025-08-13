require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "invite_user" do
    let(:organization) { create(:organization) }
    let(:invited_by) { create(:user) }
    let(:invitation) { create(:invitation, organization: organization, invited_by: invited_by) }
    let(:mail) { InvitationMailer.invite_user(invitation) }

    it "renders the headers" do
      expect(mail.subject).to eq("You're invited to join #{organization.name} on QA Lab")
      expect(mail.to).to eq([ invitation.email ])
      expect(mail.from).to eq([ "noreply@qalab.local" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("You're Invited")
    end
  end

  describe "invite_organization_owner" do
    let(:invited_by) { create(:user, :system_admin) }
    let(:invitation) { create(:invitation, :organization_owner, invited_by: invited_by) }
    let(:mail) { InvitationMailer.invite_organization_owner(invitation) }

    it "renders the headers" do
      expect(mail.subject).to eq("You're invited to create your organization on QA Lab")
      expect(mail.to).to eq([ invitation.email ])
      expect(mail.from).to eq([ "noreply@qalab.local" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("invited to create your organization")
    end

    it "includes the invitation token in the accept URL" do
      expect(mail.body.encoded).to include(invitation.token)
    end
  end
end
