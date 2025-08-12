require 'rails_helper'

RSpec.describe "Invitations", type: :request do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:admin_user) { create(:user) }
  let!(:organization_user) { create(:organization_user, user: admin_user, organization: organization, role: "admin") }
  let(:invitation) { create(:invitation, organization: organization) }

  before do
    sign_in admin_user
  end

  describe "GET /invitations" do
    it "returns http success" do
      get invitations_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /invitations/new" do
    it "returns http success" do
      get new_invitation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /invitations" do
    it "creates an invitation and redirects" do
      post invitations_path, params: { invitation: { email: "test@example.com", role: "member" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /invitations/:id" do
    it "returns http success" do
      get invitation_path(invitation)
      expect(response).to have_http_status(:success)
    end
  end
end
