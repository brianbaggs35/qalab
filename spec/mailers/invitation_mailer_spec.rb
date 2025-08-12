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
end
