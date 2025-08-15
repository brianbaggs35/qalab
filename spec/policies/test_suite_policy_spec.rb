require 'rails_helper'

RSpec.describe TestSuitePolicy, type: :policy do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }
  let(:organization) { create(:organization) }
  let(:test_suite) { create(:test_suite, user: user, organization: organization) }

  subject { described_class.new(user, test_suite) }

  describe "#index?" do
    context "with regular user in organization" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits access" do
        expect(subject.index?).to be true
      end
    end

    context "with regular user not in any organization" do
      it "denies access" do
        expect(subject.index?).to be false
      end
    end

    context "with system admin" do
      let(:admin_policy) { described_class.new(system_admin, test_suite) }

      it "denies access" do
        expect(admin_policy.index?).to be false
      end
    end
  end

  describe "#show?" do
    context "when user is a member of the organization" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to show the test suite" do
        expect(subject.show?).to be true
      end
    end

    context "when user is not a member of the organization" do
      it "does not permit the user to show the test suite" do
        expect(subject.show?).to be false
      end
    end

    context "with system admin" do
      let(:admin_policy) { described_class.new(system_admin, test_suite) }

      it "denies access" do
        expect(admin_policy.show?).to be false
      end
    end
  end

  describe "#create?" do
    context "when user is a member of the organization" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to create a test suite" do
        expect(subject.create?).to be true
      end
    end

    context "when user is not a member of any organization" do
      it "does not permit the user to create a test suite" do
        expect(subject.create?).to be false
      end
    end
  end

  describe "#new?" do
    context "when user is a member of the organization" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to create a test suite" do
        expect(subject.new?).to be true
      end
    end

    context "when user is not a member of any organization" do
      it "does not permit the user to create a test suite" do
        expect(subject.new?).to be false
      end
    end
  end

  describe "#update?" do
    context "when user owns the test suite" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to update the test suite" do
        expect(subject.update?).to be true
      end
    end

    context "when user is an owner in the organization" do
      let(:owner_user) { create(:user) }
      let(:owner_test_suite) { create(:test_suite, user: owner_user, organization: organization) }
      let(:owner_policy) { described_class.new(user, owner_test_suite) }

      before { create(:organization_user, user: user, organization: organization, role: "owner") }

      it "permits the owner to update any test suite" do
        expect(owner_policy.update?).to be true
      end
    end

    context "when user is an admin in the organization" do
      let(:admin_user) { create(:user) }
      let(:admin_test_suite) { create(:test_suite, user: admin_user, organization: organization) }
      let(:admin_policy) { described_class.new(user, admin_test_suite) }

      before { create(:organization_user, user: user, organization: organization, role: "admin") }

      it "permits the admin to update any test suite" do
        expect(admin_policy.update?).to be true
      end
    end

    context "when user is not in the same organization" do
      let(:other_organization) { create(:organization) }
      let(:other_test_suite) { create(:test_suite, organization: other_organization) }
      let(:other_policy) { described_class.new(user, other_test_suite) }

      it "does not permit the user to update the test suite" do
        expect(other_policy.update?).to be false
      end
    end
  end

  describe "#edit?" do
    context "when user owns the test suite" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to edit the test suite" do
        expect(subject.edit?).to be true
      end
    end

    context "when user is not in the same organization" do
      let(:other_organization) { create(:organization) }
      let(:other_test_suite) { create(:test_suite, organization: other_organization) }
      let(:other_policy) { described_class.new(user, other_test_suite) }

      it "does not permit the user to edit the test suite" do
        expect(other_policy.edit?).to be false
      end
    end
  end

  describe "#destroy?" do
    context "when user owns the test suite" do
      before { create(:organization_user, user: user, organization: organization, role: "member") }

      it "permits the user to destroy the test suite" do
        expect(subject.destroy?).to be true
      end
    end

    context "when user is an owner in the organization" do
      let(:owner_user) { create(:user) }
      let(:owner_test_suite) { create(:test_suite, user: owner_user, organization: organization) }
      let(:owner_policy) { described_class.new(user, owner_test_suite) }

      before { create(:organization_user, user: user, organization: organization, role: "owner") }

      it "permits the owner to destroy any test suite" do
        expect(owner_policy.destroy?).to be true
      end
    end

    context "when user is an admin in the organization" do
      let(:admin_user) { create(:user) }
      let(:admin_test_suite) { create(:test_suite, user: admin_user, organization: organization) }
      let(:admin_policy) { described_class.new(user, admin_test_suite) }

      before { create(:organization_user, user: user, organization: organization, role: "admin") }

      it "permits the admin to destroy any test suite" do
        expect(admin_policy.destroy?).to be true
      end
    end

    context "when user is not owner/admin and not in same organization" do
      let(:other_organization) { create(:organization) }
      let(:other_test_suite) { create(:test_suite, organization: other_organization) }
      let(:other_policy) { described_class.new(user, other_test_suite) }

      it "does not permit the user to destroy the test suite" do
        expect(other_policy.destroy?).to be false
      end
    end
  end

  describe "Scope" do
    let(:organization2) { create(:organization) }
    let!(:test_suite1) { create(:test_suite, organization: organization) }
    let!(:test_suite2) { create(:test_suite, organization: organization2) }

    context "with regular user in organization" do
      before do
        create(:organization_user, user: user, organization: organization, role: "member")
      end

      it "returns test suites from user organizations" do
        scope = described_class::Scope.new(user, TestSuite.all).resolve
        expect(scope).to include(test_suite1)
        expect(scope).not_to include(test_suite2)
      end
    end

    context "with user in multiple organizations" do
      before do
        create(:organization_user, user: user, organization: organization, role: "member")
        create(:organization_user, user: user, organization: organization2, role: "member")
      end

      it "returns test suites from first organization only (current implementation)" do
        scope = described_class::Scope.new(user, TestSuite.all).resolve
        # The current implementation uses user.organizations.first, so we test that it returns
        # test suites from exactly one organization (whichever comes first)
        expect(scope.count).to eq(1)
        expect([ test_suite1, test_suite2 ]).to include(*scope.to_a)
      end
    end

    context "with system admin" do
      it "returns no test suites" do
        scope = described_class::Scope.new(system_admin, TestSuite.all).resolve
        expect(scope).to be_empty
      end
    end
  end
end
