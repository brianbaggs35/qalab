require 'rails_helper'

RSpec.describe SystemAdmin::DashboardController, type: :controller do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }

  describe "GET #index" do
    context "with system admin" do
      before { sign_in system_admin }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns required instance variables' do
        get :index
        expect(assigns(:total_users)).to be_present
        expect(assigns(:total_organizations)).to be_present
        expect(assigns(:system_admins_count)).to be_present
      end
    end

    context "with regular user" do
      before { sign_in user }

      it "redirects with access denied" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #logs' do
    context 'with system admin' do
      before { sign_in system_admin }

      it 'returns success' do
        get :logs
        expect(response).to have_http_status(:success)
      end

      it 'assigns log files' do
        get :logs
        expect(assigns(:log_files)).to be_present
        expect(assigns(:selected_log)).to be_present
        expect(assigns(:log_content)).to be_present
        expect(assigns(:lines_to_show)).to be_present
      end

      it 'respects log file parameter' do
        get :logs, params: { log: 'test.log' }
        expect(assigns(:selected_log)).to eq('test.log')
      end

      it 'respects lines parameter' do
        get :logs, params: { lines: 200 }
        expect(assigns(:lines_to_show)).to eq(200)
      end
    end

    context 'with regular user' do
      before { sign_in user }

      it 'redirects with access denied' do
        get :logs
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe 'GET #system_settings' do
    context 'with system admin' do
      before { sign_in system_admin }

      it 'returns success' do
        get :system_settings
        expect(response).to have_http_status(:success)
      end

      it 'assigns smtp settings' do
        get :system_settings
        expect(assigns(:smtp_settings)).to be_present
      end
    end

    context 'with regular user' do
      before { sign_in user }

      it 'redirects with access denied' do
        get :system_settings
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe 'POST #update_system_settings' do
    context 'with system admin' do
      before { sign_in system_admin }

      let(:smtp_params) do
        {
          smtp: {
            address: 'smtp.gmail.com',
            port: '587',
            username: 'test@example.com',
            password: 'password123',
            from_email: 'noreply@example.com'
          }
        }
      end

      it 'updates smtp settings and redirects with success notice' do
        expect(SystemSetting).to receive(:update_smtp_settings).with(smtp_params[:smtp])
        
        post :update_system_settings, params: smtp_params
        
        expect(response).to redirect_to(system_admin_system_settings_path)
        expect(flash[:notice]).to eq('SMTP settings updated successfully!')
      end

      it 'handles errors gracefully' do
        allow(SystemSetting).to receive(:update_smtp_settings).and_raise(StandardError.new('Test error'))
        
        post :update_system_settings, params: smtp_params
        
        expect(response).to redirect_to(system_admin_system_settings_path)
        expect(flash[:alert]).to include('Error updating settings')
      end
    end

    context 'with regular user' do
      before { sign_in user }

      it 'redirects with access denied' do
        post :update_system_settings, params: { smtp: { address: 'test' } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end
end
