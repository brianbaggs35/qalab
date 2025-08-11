require 'rails_helper'

RSpec.describe AutomatedTesting::ResultsController, type: :controller do
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

    context "when not signed in" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #show" do
    before { sign_in user }

    it "returns success" do
      get :show, params: { id: 1 }
      expect(response).to have_http_status(:success)
    end
  end
end