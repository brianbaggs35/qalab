require 'rails_helper'

RSpec.describe Users::ConfirmationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#show' do
    context 'with valid confirmation token' do
      let(:user) { create(:user, confirmed_at: nil) }
      let(:token) { user.confirmation_token }

      it 'confirms the user and redirects to sign in' do
        get :show, params: { confirmation_token: token }

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:notice]).to be_present
        user.reload
        expect(user).to be_confirmed
      end
    end

    context 'with invalid confirmation token' do
      it 'renders the new template with errors' do
        get :show, params: { confirmation_token: 'invalid_token' }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end

    context 'when user is already confirmed' do
      let(:user) { create(:user, :confirmed) }
      let(:token) { user.confirmation_token }

      it 'renders new template with error' do
        get :show, params: { confirmation_token: token }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#after_confirmation_path_for' do
    let(:user) { create(:user) }

    it 'redirects to root when user is signed in' do
      sign_in user
      path = controller.send(:after_confirmation_path_for, :user, user)
      expect(path).to eq(root_path)
    end

    it 'redirects to sign in when user is not signed in' do
      path = controller.send(:after_confirmation_path_for, :user, user)
      expect(path).to eq(new_user_session_path)
    end
  end
end
