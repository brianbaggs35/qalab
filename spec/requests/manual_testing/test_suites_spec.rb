require 'rails_helper'

RSpec.describe "ManualTesting::TestSuites", type: :request do
  describe "GET /index" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get manual_testing_test_suites_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:organization) { create(:organization) }
      let(:user) { create(:user, :onboarded) }

      before do
        sign_in user
        organization.organization_users.create!(user: user, role: "member")
      end

      it "returns http success" do
        get manual_testing_test_suites_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /show" do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :onboarded) }
    let(:test_suite) { create(:test_suite, organization: organization, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        get manual_testing_test_suite_path(test_suite)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in user
        organization.organization_users.create!(user: user, role: "member")
      end

      it "returns http success" do
        get manual_testing_test_suite_path(test_suite)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /new" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get new_manual_testing_test_suite_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:organization) { create(:organization) }
      let(:user) { create(:user, :onboarded) }

      before do
        sign_in user
        organization.organization_users.create!(user: user, role: "member")
      end

      it "returns http success" do
        get new_manual_testing_test_suite_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /create" do
    context "when not authenticated" do
      it "redirects to sign in" do
        post manual_testing_test_suites_path, params: { test_suite: { name: "Test Suite" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      let(:organization) { create(:organization) }
      let(:user) { create(:user, :onboarded) }

      before do
        sign_in user
        organization.organization_users.create!(user: user, role: "member")
      end

      it "redirects after successful creation" do
        post manual_testing_test_suites_path, params: { test_suite: { name: "Test Suite", description: "Test Description" } }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /edit" do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :onboarded) }
    let(:test_suite) { create(:test_suite, organization: organization, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        get edit_manual_testing_test_suite_path(test_suite)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in user
        organization.organization_users.create!(user: user, role: "member")
      end

      it "returns http success" do
        get edit_manual_testing_test_suite_path(test_suite)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /update" do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :onboarded) }
    let(:test_suite) { create(:test_suite, organization: organization, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        patch manual_testing_test_suite_path(test_suite), params: { test_suite: { name: "Updated Name" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in user
        organization.organization_users.create!(user: user, role: "member")
      end

      it "redirects after successful update" do
        patch manual_testing_test_suite_path(test_suite), params: { test_suite: { name: "Updated Name" } }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "DELETE /destroy" do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, :onboarded) }
    let(:test_suite) { create(:test_suite, organization: organization, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        delete manual_testing_test_suite_path(test_suite)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in user
        organization.organization_users.create!(user: user, role: "member")
      end

      it "redirects after successful deletion" do
        delete manual_testing_test_suite_path(test_suite)
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
