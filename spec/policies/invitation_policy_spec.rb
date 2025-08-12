require 'rails_helper'

RSpec.describe InvitationPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, role: "system_admin") }
  let(:invitation) { create(:invitation, organization: organization) }

  subject { described_class }

  describe ".scope" do
    it "returns all invitations for system admin" do
      expect(described_class::Scope.new(system_admin, Invitation).resolve).to eq(Invitation.all)
    end

    it "returns organization invitations for admin users" do
      create(:organization_user, user: user, organization: organization, role: "admin")
      expect(described_class::Scope.new(user, Invitation).resolve).to include(invitation)
    end
  end

  describe "show?" do
    it "permits system admin" do
      expect(described_class.new(system_admin, invitation)).to be_show
    end

    it "permits admin users in same organization" do
      create(:organization_user, user: user, organization: organization, role: "admin")
      expect(described_class.new(user, invitation)).to be_show
    end
  end

  describe "create?" do
    it "permits system admin" do
      expect(described_class.new(system_admin, invitation)).to be_create
    end

    it "permits admin users to create invitations" do
      create(:organization_user, user: user, organization: organization, role: "admin")
      expect(described_class.new(user, invitation)).to be_create
    end
  end

  describe "destroy?" do
    it "permits system admin" do
      expect(described_class.new(system_admin, invitation)).to be_destroy
    end

    it "permits admin users in same organization" do
      create(:organization_user, user: user, organization: organization, role: "admin")
      expect(described_class.new(user, invitation)).to be_destroy
    end
  end
end
