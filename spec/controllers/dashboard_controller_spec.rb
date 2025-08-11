require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, role: 'system_admin') }

  let!(:org_user) { create(:organization_user, organization: organization, user: user, role: 'member') }

  describe 'GET #index' do
    context 'with regular user' do
      before { sign_in user }

      it 'returns success' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns test run statistics' do
        get :index
        expect(assigns(:test_run_stats)).to include(:total, :completed, :failed, :pending, :processing)
      end

      it 'assigns recent test runs' do
        test_run = create(:test_run, organization: organization, user: user)
        get :index
        expect(assigns(:recent_test_runs)).to include(test_run)
      end

      it 'calculates overall success rate' do
        get :index
        expect(assigns(:overall_success_rate)).to be_a(Numeric)
      end
    end

    context 'with system admin' do
      before { sign_in system_admin }

      it 'redirects to system admin dashboard' do
        get :index
        expect(response).to redirect_to(system_admin_dashboard_path)
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end