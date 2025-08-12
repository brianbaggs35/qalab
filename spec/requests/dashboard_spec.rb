require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, :onboarded) }

  before do
    sign_in user
    # Add user to organization so they don't need onboarding
    organization.organization_users.create!(user: user, role: "member")
  end

  describe "GET /dashboard" do
    it "returns http success" do
      get dashboard_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dashboard")
      expect(response.body).to include("Welcome back, #{user.first_name}")
    end
  end
end
