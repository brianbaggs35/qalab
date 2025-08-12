require 'rails_helper'

RSpec.describe OnboardingController, type: :request do
  let(:user) { create(:user, :confirmed, onboarding_completed_at: nil) }

  before do
    sign_in user
  end

  describe "GET #welcome" do
    context "when user needs onboarding" do
      it "renders welcome page" do
        get onboarding_welcome_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome to QA Lab!")
      end
    end

    context "when user already completed onboarding" do
      before do
        user.update!(onboarding_completed_at: Time.current)
        organization = create(:organization)
        organization.organization_users.create!(user: user, role: "owner")
      end

      it "redirects to dashboard" do
        get onboarding_welcome_path

        expect(response).to redirect_to(dashboard_path)
      end
    end
  end

  describe "GET #organization" do
    it "renders organization creation form" do
      get onboarding_organization_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create Your Organization")
    end

    it "shows first organization message when no organizations exist" do
      Organization.destroy_all

      get onboarding_organization_path

      expect(response.body).to include("Welcome First User!")
    end
  end

  describe "POST #create_organization" do
    let(:organization_params) { { organization: { name: "Test Organization" } } }

    context "with valid parameters" do
      it "creates organization and completes onboarding" do
        expect {
          post onboarding_organization_path, params: organization_params
        }.to change(Organization, :count).by(1)
           .and change { user.reload.onboarding_completed_at }.from(nil)

        organization = Organization.last
        expect(organization.name).to eq("Test Organization")
        expect(user.owner_of?(organization)).to be true
        expect(response).to redirect_to(onboarding_complete_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { organization: { name: "" } } }

      it "renders organization form with errors" do
        post onboarding_organization_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Create Your Organization")
      end
    end
  end

  describe "GET #complete" do
    let!(:organization) { create(:organization) }
    
    before do
      organization.organization_users.create!(user: user, role: "owner")
    end

    it "renders completion page" do
      get onboarding_complete_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You're All Set!")
    end
  end
end