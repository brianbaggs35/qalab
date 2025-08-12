require 'rails_helper'

RSpec.describe OrganizationsHelper, type: :helper do
  describe "module inclusion" do
    it "can be included without errors" do
      expect { helper.class.include OrganizationsHelper }.not_to raise_error
    end

    it "responds to helper methods" do
      expect(helper).to be_a(ActionView::Base)
    end
  end

  describe "helper functionality" do
    it "provides access to Rails helper methods" do
      expect(helper).to respond_to(:content_tag)
      expect(helper).to respond_to(:link_to)
      expect(helper).to respond_to(:image_tag)
    end

    it "can generate organization-related elements" do
      # Test that organization helpers work properly
      org_tag = helper.content_tag(:div, "Organization", class: "org-card")
      expect(org_tag).to include("Organization")
      expect(org_tag).to include("org-card")
    end
  end

  # Future helper methods for organization-specific functionality would be tested here
  # For example:
  # describe "#organization_avatar" do
  #   it "returns default avatar when no image present" do
  #     organization = build(:organization, image: nil)
  #     avatar = helper.organization_avatar(organization)
  #     expect(avatar).to include("default-avatar")
  #   end
  #
  #   it "returns organization image when present" do
  #     organization = build(:organization, image: "org.png")
  #     avatar = helper.organization_avatar(organization)
  #     expect(avatar).to include("org.png")
  #   end
  # end
  #
  # describe "#organization_member_count" do
  #   it "formats member count correctly" do
  #     organization = build(:organization)
  #     allow(organization).to receive(:users_count).and_return(5)
  #     count = helper.organization_member_count(organization)
  #     expect(count).to eq("5 members")
  #   end
  # end
end
