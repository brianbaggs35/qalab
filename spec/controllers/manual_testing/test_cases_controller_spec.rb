require 'rails_helper'

RSpec.describe ManualTesting::TestCasesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }
  let(:test_case) { create(:test_case, user: user, organization: organization) }

  before do
    organization.organization_users.create!(user: user, role: 'member')
  end

  describe "GET #index" do
    context "with regular user" do
      before { sign_in user }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:test_cases)).to be_an(ActiveRecord::Relation)
        expect(assigns(:stats)).to be_present
      end

      it "shows test cases for user's organization" do
        test_case # Create the test case
        get :index
        expect(assigns(:test_cases)).to include(test_case)
      end
    end

    context "with system admin" do
      before { sign_in system_admin }

      it "redirects to system admin dashboard" do
        get :index
        expect(response).to redirect_to(system_admin_dashboard_path)
      end
    end
  end

  describe "GET #new" do
    before { sign_in user }

    it "returns success and assigns new test case" do
      get :new
      expect(response).to have_http_status(:success)
      expect(assigns(:test_case)).to be_a(TestCase)
      expect(assigns(:test_case)).to be_new_record
    end
  end

  describe "POST #create" do
    before { sign_in user }

    context "with valid parameters" do
      let(:valid_params) do
        {
          test_case: {
            title: "Test Login Functionality",
            priority: "high",
            description: "Test user login",
            expected_results: "User should be logged in",
            category: "functional",
            steps: '["Step 1", "Step 2"]'
          }
        }
      end

      it "creates a test case and redirects" do
        expect {
          post :create, params: valid_params
        }.to change(TestCase, :count).by(1)

        expect(response).to redirect_to(manual_testing_test_cases_path)
        expect(flash[:notice]).to include("created successfully")
      end

      it "sets the correct attributes" do
        post :create, params: valid_params
        test_case = TestCase.last
        expect(test_case.title).to eq("Test Login Functionality")
        expect(test_case.priority).to eq("high")
        expect(test_case.user).to eq(user)
        expect(test_case.organization).to eq(organization)
        expect(test_case.steps).to eq([ "Step 1", "Step 2" ])
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          test_case: {
            title: "", # Invalid - required
            priority: "high"
          }
        }
      end

      it "does not create a test case" do
        expect {
          post :create, params: invalid_params
        }.not_to change(TestCase, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "saving as draft" do
      let(:draft_params) do
        {
          test_case: {
            title: "Draft Test Case",
            priority: "medium",
            expected_results: "Some result"
          },
          draft: true
        }
      end

      it "creates test case with draft status" do
        post :create, params: draft_params
        test_case = TestCase.last
        expect(test_case.status).to eq("draft")
      end
    end
  end

  describe "GET #show" do
    before { sign_in user }

    it "returns success" do
      get :show, params: { id: test_case.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:test_case)).to eq(test_case)
    end
  end

  describe "GET #edit" do
    before { sign_in user }

    it "returns success" do
      get :edit, params: { id: test_case.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:test_case)).to eq(test_case)
    end
  end

  describe "PATCH #update" do
    before { sign_in user }

    context "with valid parameters" do
      let(:update_params) do
        {
          id: test_case.id,
          test_case: {
            title: "Updated Test Case Title"
          }
        }
      end

      it "updates the test case and redirects" do
        patch :update, params: update_params
        test_case.reload
        expect(test_case.title).to eq("Updated Test Case Title")
        expect(response).to redirect_to(manual_testing_test_case_path(test_case))
        expect(flash[:notice]).to include("updated successfully")
      end
    end
  end

  describe "DELETE #destroy" do
    before { sign_in user }

    it "deletes the test case and redirects" do
      test_case # Create the test case
      expect {
        delete :destroy, params: { id: test_case.id }
      }.to change(TestCase, :count).by(-1)

      expect(response).to redirect_to(manual_testing_test_cases_path)
      expect(flash[:notice]).to include("deleted successfully")
    end
  end
end
