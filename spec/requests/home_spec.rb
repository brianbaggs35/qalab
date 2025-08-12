require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /home/index" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get home_index_path
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
        get home_index_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get root_path
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
        get root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
