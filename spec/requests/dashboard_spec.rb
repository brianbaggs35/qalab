require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /dashboard" do
    it "returns http success" do
      get dashboard_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Dashboard")
      expect(response.body).to include("Welcome back, #{user.first_name}")
    end
  end
end
