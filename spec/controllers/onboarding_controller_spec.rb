require 'rails_helper'

RSpec.describe OnboardingController, type: :controller do
  let(:user) { create(:user, :confirmed, onboarding_completed_at: nil) }

  before do
    sign_in user
  end

  describe '#welcome' do
    it 'assigns current user' do
      get :welcome
      expect(assigns(:user)).to eq(user)
      expect(response).to have_http_status(:success)
    end

    it 'redirects if onboarding already completed' do
      user.update!(onboarding_completed_at: Time.current)
      get :welcome
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects if user already belongs to organization' do
      organization = create(:organization)
      create(:organization_user, user: user, organization: organization)
      get :welcome
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe '#organization' do
    it 'creates new organization and checks if first' do
      Organization.destroy_all # Ensure no organizations
      get :organization
      expect(assigns(:organization)).to be_a_new(Organization)
      expect(assigns(:is_first_organization)).to be true
      expect(response).to have_http_status(:success)
    end

    it 'identifies when not first organization' do
      create(:organization) # Create existing organization
      get :organization
      expect(assigns(:is_first_organization)).to be false
    end
  end

  describe '#create_organization' do
    it 'creates organization and completes onboarding' do
      Organization.destroy_all
      
      expect {
        post :create_organization, params: { organization: { name: 'Test Org' } }
      }.to change(Organization, :count).by(1)
      
      organization = Organization.last
      expect(organization.name).to eq('Test Org')
      expect(organization.organization_users.where(user: user, role: 'owner')).to exist
      
      user.reload
      expect(user.onboarding_completed_at).to be_present
      expect(response).to redirect_to(onboarding_complete_path)
    end

    it 'renders organization template with errors on invalid params' do
      post :create_organization, params: { organization: { name: '' } }
      expect(response).to render_template(:organization)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(assigns(:organization).errors[:name]).to be_present
    end
  end

  describe '#complete' do
    let(:organization) { create(:organization) }
    
    before do
      create(:organization_user, user: user, organization: organization, role: 'owner')
      user.update!(onboarding_completed_at: Time.current)
    end

    it 'assigns user\'s first organization' do
      get :complete
      expect(assigns(:organization)).to eq(organization)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'before_action filters' do
    it 'requires authentication' do
      sign_out user
      get :welcome
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end