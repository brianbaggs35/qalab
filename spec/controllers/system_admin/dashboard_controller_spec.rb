require 'rails_helper'

RSpec.describe SystemAdmin::DashboardController, type: :controller do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }

  describe "GET #index" do
    context "with system admin" do
      before { sign_in system_admin }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
