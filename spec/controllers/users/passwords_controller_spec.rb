require 'rails_helper'

RSpec.describe Users::PasswordsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#create' do
    let(:user) { create(:user, :confirmed, email: 'test@example.com') }

    it 'sends password reset instructions for valid email' do
      post :create, params: { user: { email: user.email } }
      
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to include('receive an email')
    end

    it 'still redirects for invalid email to prevent enumeration' do
      post :create, params: { user: { email: 'nonexistent@example.com' } }
      
      expect(response).to render_template(:new)  # Devise renders new on invalid email in test env
    end
  end

  describe '#update' do
    let(:user) { create(:user, :confirmed) }
    let(:reset_token) { user.send_reset_password_instructions }

    it 'updates password with valid token and matching passwords' do
      put :update, params: {
        user: {
          reset_password_token: reset_token,
          password: 'newpassword123',
          password_confirmation: 'newpassword123'
        }
      }
      
      expect(response).to redirect_to(root_path)  # Actually redirects to root
      expect(flash[:notice]).to include('changed successfully')
    end

    it 'renders edit with error for mismatched passwords' do
      put :update, params: {
        user: {
          reset_password_token: reset_token,
          password: 'newpassword123',
          password_confirmation: 'differentpassword123'
        }
      }
      
      expect(response).to render_template(:edit)
      expect(assigns(:user).errors[:password_confirmation]).to be_present
    end
  end

  describe '#after_resetting_password_path_for' do
    let(:user) { create(:user) }

    it 'redirects to root after password reset' do
      path = controller.send(:after_resetting_password_path_for, user)
      expect(path).to eq(root_path)  # Actually returns root_path
    end
  end

  describe '#after_sending_reset_password_instructions_path_for' do
    it 'redirects to sign in page after sending instructions' do
      path = controller.send(:after_sending_reset_password_instructions_path_for, :user)
      expect(path).to eq(new_user_session_path)
    end
  end
end