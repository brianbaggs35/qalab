require 'rails_helper'

RSpec.describe TestCasePolicy, type: :policy do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }
  let(:organization) { create(:organization) }
  let(:test_case) { create(:test_case, user: user, organization: organization) }

  subject { described_class.new(user, test_case) }

  describe "#index?" do
    context "with regular user" do
      it "permits access" do
        expect(subject.index?).to be true
      end
    end

    context "with system admin" do
      let(:admin_policy) { described_class.new(system_admin, test_case) }
      
      it "denies access" do
        expect(admin_policy.index?).to be false
      end
    end
  end

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

    context "with system admin" do
      let(:admin_policy) { described_class.new(system_admin, test_case) }

      it "denies access" do
        expect(admin_policy.show?).to be false
      end
    end
  end

  describe "#new?" do
    context "when user is a member of the organization" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to create a test case" do
        expect(subject.new?).to be true
      end
    end

    context "when user is not a member of the organization" do
      it "does not permit the user to create a test case" do
        expect(subject.new?).to be false
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

  describe "#edit?" do
    context "when user owns the test case" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to edit the test case" do
        expect(subject.edit?).to be true
      end
    end

    context "when user is not in organization" do
      let(:other_user) { create(:user) }
      let(:other_organization) { create(:organization) }
      let(:other_test_case) { create(:test_case, user: other_user, organization: other_organization) }
      let(:other_policy) { described_class.new(user, other_test_case) }

      it "does not permit editing" do
        expect(other_policy.edit?).to be false
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

  describe "Scope" do
    let(:organization2) { create(:organization) }
    let!(:test_case1) { create(:test_case, organization: organization) }
    let!(:test_case2) { create(:test_case, organization: organization2) }

    context "with regular user in organizations" do
      before do
        create(:organization_user, user: user, organization: organization, role: "member")
      end

      it "returns test cases from user organizations" do
        scope = described_class::Scope.new(user, TestCase.all).resolve
        expect(scope).to include(test_case1)
        expect(scope).not_to include(test_case2)
      end
    end

    context "with system admin" do
      it "returns no test cases" do
        scope = described_class::Scope.new(system_admin, TestCase.all).resolve
        expect(scope).to be_empty
      end
    end
  end
end
