require 'rails_helper'

RSpec.describe InvitationsHelper, type: :helper do
  describe "module inclusion" do
    it "can be included without errors" do
      expect { helper.class.include InvitationsHelper }.not_to raise_error
    end

    it "responds to helper methods" do
      expect(helper).to be_a(ActionView::Base)
    end
  end

  describe "helper functionality" do
    it "provides access to Rails helper methods" do
      expect(helper).to respond_to(:content_tag)
      expect(helper).to respond_to(:link_to)
      expect(helper).to respond_to(:form_with)
    end

    it "can generate form elements" do
      # Test that form helpers work through the invitation helper
      form_tag = helper.content_tag(:form, "test form", class: "invitation-form")
      expect(form_tag).to include("test form")
      expect(form_tag).to include("invitation-form")
    end
  end

  # Future helper methods for invitation-specific functionality would be tested here
  # For example:
  # describe "#invitation_status_badge" do
  #   it "generates appropriate badge for pending invitations" do
  #     badge = helper.invitation_status_badge("pending")
  #     expect(badge).to include("badge-warning")
  #   end
  #
  #   it "generates appropriate badge for accepted invitations" do
  #     badge = helper.invitation_status_badge("accepted")
  #     expect(badge).to include("badge-success")
  #   end
  # end
end
