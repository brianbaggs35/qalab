require 'rails_helper'

RSpec.describe TestCasePolicy, type: :policy do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:test_case) { create(:test_case, user: user, organization: organization) }

  subject { described_class.new(user, test_case) }

  describe "#show?" do
    context "when user is a member of the organization" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to show the test case" do
        expect(subject.show?).to be true
      end
    end

    context "when user is not a member of the organization" do
      it "does not permit the user to show the test case" do
        expect(subject.show?).to be false
      end
    end
  end

  describe "#create?" do
    context "when user is a member of the organization" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to create a test case" do
        expect(subject.create?).to be true
      end
    end

    context "when user is not a member of the organization" do
      it "does not permit the user to create a test case" do
        expect(subject.create?).to be false
      end
    end
  end

  describe "#update?" do
    context "when user owns the test case" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to update the test case" do
        expect(subject.update?).to be true
      end
    end

    context "when user is an admin in the organization" do
      let(:admin_user) { create(:user) }
      let(:admin_test_case) { create(:test_case, user: admin_user, organization: organization) }
      let(:admin_policy) { described_class.new(user, admin_test_case) }

      before { create(:organization_user, user: user, organization: organization, role: "admin") }

      it "permits the admin to update any test case" do
        expect(admin_policy.update?).to be true
      end
    end

    context "when user is not the owner and not an admin" do
      let(:other_user) { create(:user) }
      let(:other_organization) { create(:organization) }
      let(:other_test_case) { create(:test_case, user: other_user, organization: other_organization) }
      let(:other_policy) { described_class.new(user, other_test_case) }

      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "does not permit the user to update the test case from different org" do
        expect(other_policy.update?).to be false
      end
    end
  end

  describe "#destroy?" do
    context "when user owns the test case" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to destroy the test case" do
        expect(subject.destroy?).to be true
      end
    end

    context "when user is an admin in the organization" do
      let(:admin_user) { create(:user) }
      let(:admin_test_case) { create(:test_case, user: admin_user, organization: organization) }
      let(:admin_policy) { described_class.new(user, admin_test_case) }

      before { create(:organization_user, user: user, organization: organization, role: "admin") }

      it "permits the admin to destroy any test case" do
        expect(admin_policy.destroy?).to be true
      end
    end
  end
end
