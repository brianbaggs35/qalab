require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#create' do
    context 'when no organizations exist (first user)' do
      before { Organization.destroy_all }

      it 'allows registration without invitation token' do
        post :create, params: {
          user: {
            first_name: 'John',
            last_name: 'Doe',
            email: 'john@example.com',
            password: 'password123456',
            password_confirmation: 'password123456',
            invitation_token: ''
          }
        }

        expect(response).to redirect_to(onboarding_welcome_path)  # First user should go to welcome page
        expect(User.find_by(email: 'john@example.com')).to be_present
      end
    end

    context 'when organizations exist' do
      let!(:organization) { create(:organization) }
      let!(:invitation) { create(:invitation, email: 'invited@example.com', organization: organization) }

      it 'requires invitation token' do
        post :create, params: {
          user: {
            first_name: 'Jane',
            last_name: 'Doe',
            email: 'jane@example.com',
            password: 'password123456',
            password_confirmation: 'password123456',
            invitation_token: ''
          }
        }

        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:alert]).to include('Sign ups are by invitation only')
      end

      it 'allows registration with valid invitation token' do
        post :create, params: {
          user: {
            first_name: 'Jane',
            last_name: 'Smith',
            email: 'invited@example.com',
            password: 'password123456',
            password_confirmation: 'password123456',
            invitation_token: invitation.token
          }
        }

        expect(response).to redirect_to(dashboard_path)  # Invited users go to dashboard
        user = User.find_by(email: 'invited@example.com')
        expect(user).to be_present
        expect(user.first_name).to eq('Jane')
        expect(user.last_name).to eq('Smith')
      end

      it 'rejects registration with invalid invitation token' do
        post :create, params: {
          user: {
            first_name: 'Jane',
            last_name: 'Smith',
            email: 'jane@example.com',
            password: 'password123456',
            password_confirmation: 'password123456',
            invitation_token: 'invalid_token'
          }
        }

        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:alert]).to include('Invalid or expired invitation')
      end

      it 'validates email matches invitation' do
        post :create, params: {
          user: {
            first_name: 'Jane',
            last_name: 'Smith',
            email: 'different@example.com',
            password: 'password123456',
            password_confirmation: 'password123456',
            invitation_token: invitation.token
          }
        }

        expect(response).to redirect_to(new_user_registration_path)
        expect(flash[:alert]).to include('Email address must match')
      end
    end
  end

  describe '#configure_sign_up_params' do
    it 'permits invitation_token parameter' do
      params = ActionController::Parameters.new({
        user: {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john@example.com',
          password: 'password123',
          invitation_token: 'token123'
        }
      })

      controller.params = params
      controller.send(:configure_sign_up_params)

      sanitizer = controller.devise_parameter_sanitizer
      permitted = sanitizer.sanitize(:sign_up)

      expect(permitted.keys).to include('invitation_token')
    end
  end

  describe "Pundit authorization skipping" do
    let(:controller_instance) { described_class.new }

    it "skips pundit authorization" do
      expect(controller_instance.send(:skip_pundit_authorization?)).to be true
    end

    it "skips authorization" do
      expect(controller_instance.send(:skip_authorization?)).to be true
    end
  end

  describe "after_sign_up_path_for" do
    let(:user) { create(:user) }

    it "redirects to onboarding welcome path" do
      path = controller.send(:after_sign_up_path_for, user)
      expect(path).to eq(onboarding_welcome_path)
    end
  end
end
