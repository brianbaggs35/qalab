require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:record) { double("record") }
  let(:policy) { described_class.new(user, record) }

  describe "#initialize" do
    it "sets the user and record" do
      expect(policy.user).to eq(user)
      expect(policy.record).to eq(record)
    end
  end

  describe "default permissions" do
    it "denies index by default" do
      expect(policy.index?).to be false
    end

    it "denies show by default" do
      expect(policy.show?).to be false
    end

    it "denies create by default" do
      expect(policy.create?).to be false
    end

    it "denies new by default" do
      expect(policy.new?).to be false
    end

    it "denies update by default" do
      expect(policy.update?).to be false
    end

    it "denies edit by default" do
      expect(policy.edit?).to be false
    end

    it "denies destroy by default" do
      expect(policy.destroy?).to be false
    end
  end

  describe "Scope" do
    let(:scope) { double("scope") }
    let(:policy_scope) { ApplicationPolicy::Scope.new(user, scope) }

    describe "#initialize" do
      it "sets the user and scope" do
        expect(policy_scope.send(:user)).to eq(user)
        expect(policy_scope.send(:scope)).to eq(scope)
      end
    end

    describe "#resolve" do
      it "raises NoMethodError" do
        expect { policy_scope.resolve }.to raise_error(NoMethodError, /You must define #resolve/)
      end
    end
  end
end
