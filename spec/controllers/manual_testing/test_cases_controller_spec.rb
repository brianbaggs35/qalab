require 'rails_helper'

RSpec.describe ManualTesting::TestCasesController, type: :controller do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }

  describe "GET #index" do
    context "with regular user" do
      before { sign_in user }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
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

  describe "POST #create" do
    before { sign_in user }

    it "redirects with success notice" do
      post :create
      expect(response).to redirect_to(manual_testing_cases_path)
      expect(flash[:notice]).to eq("Test case created successfully!")
    end
  end

  describe "PATCH #update" do
    before { sign_in user }

    it "redirects with success notice" do
      patch :update, params: { id: 1 }
      expect(response).to redirect_to(manual_testing_cases_path)
      expect(flash[:notice]).to eq("Test case updated successfully!")
    end
  end

  describe "DELETE #destroy" do
    before { sign_in user }

    it "redirects with success notice" do
      delete :destroy, params: { id: 1 }
      expect(response).to redirect_to(manual_testing_cases_path)
      expect(flash[:notice]).to eq("Test case deleted successfully!")
    end
  end
end
