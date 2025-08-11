require 'rails_helper'

RSpec.describe "Organizations", type: :request do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }
  let(:organization) { create(:organization) }

  describe "GET /organizations" do
    context "with system admin" do
      before { sign_in system_admin }

      it "returns http success" do
        get organizations_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "returns organizations user belongs to" do
        create(:organization_user, user: user, organization: organization)
        get organizations_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /organizations/:id" do
    let(:org_user) { create(:organization_user, user: user, organization: organization) }

    before do
      org_user
      sign_in user
    end

    it "returns http success" do
      get organization_path(organization)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /organizations/new" do
    before { sign_in user }

    it "returns http success" do
      get new_organization_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /organizations" do
    before { sign_in user }

    it "creates organization successfully" do
      expect {
        post organizations_path, params: { organization: { name: "Test Organization" } }
      }.to change(Organization, :count).by(1)
      
      expect(response).to redirect_to(Organization.last)
    end

    it "creates organization_user relationship" do
      expect {
        post organizations_path, params: { organization: { name: "Test Organization" } }
      }.to change(OrganizationUser, :count).by(1)
      
      org_user = OrganizationUser.last
      expect(org_user.user).to eq(user)
      expect(org_user.role).to eq('owner')
    end
  end
end
