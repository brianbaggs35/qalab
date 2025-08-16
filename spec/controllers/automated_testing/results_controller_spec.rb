require 'rails_helper'

RSpec.describe AutomatedTesting::ResultsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:system_admin) { create(:user, role: 'system_admin') }

  let!(:org_user) { create(:organization_user, organization: organization, user: user, role: 'member') }
  let!(:other_org_user) { create(:organization_user, organization: other_organization, user: other_user, role: 'member') }

  let!(:test_run) { create(:test_run, organization: organization, user: user) }
  let!(:other_test_run) { create(:test_run, organization: other_organization, user: other_user) }

  describe 'GET #index' do
    context 'with regular user' do
      before { sign_in user }

      it 'returns success' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns test runs scoped to user organizations' do
        get :index
        expect(assigns(:test_runs)).to include(test_run)
        expect(assigns(:test_runs)).not_to include(other_test_run)
      end

      it 'assigns statistics' do
        get :index
        expect(assigns(:stats)).to include(:total, :completed, :failed, :pending, :processing)
      end

      it 'assigns environment options' do
        get :index
        expect(assigns(:environments)).to be_an(Array)
      end

      context 'with filters' do
        it 'filters by environment' do
          test_run.update!(environment: 'production')
          get :index, params: { environment: 'production' }
          expect(assigns(:test_runs)).to include(test_run)
        end

        it 'filters by status' do
          test_run.update!(status: 'completed')
          get :index, params: { status: 'completed' }
          expect(assigns(:test_runs)).to include(test_run)
        end

        it 'filters by search term' do
          test_run.update!(name: 'Unique Test Name')
          get :index, params: { search: 'Unique' }
          expect(assigns(:test_runs)).to include(test_run)
        end

        it 'filters by date range' do
          test_run.update!(created_at: 1.day.ago)
          get :index, params: {
            start_date: 2.days.ago.to_date.to_s,
            end_date: Date.current.to_s
          }
          expect(assigns(:test_runs)).to include(test_run)
        end
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

  describe 'GET #show' do
    context 'with regular user' do
      before { sign_in user }

      it 'returns success for own test run' do
        get :show, params: { id: test_run.id }
        expect(response).to be_successful
      end

      it 'assigns test run' do
        get :show, params: { id: test_run.id }
        expect(assigns(:test_run)).to eq(test_run)
      end

      it 'assigns test results' do
        # Create test results for this test run
        create(:test_result, test_run: test_run, name: 'Test 1', status: 'passed')
        get :show, params: { id: test_run.id }
        expect(assigns(:test_results)).to be_present
      end

      it 'redirects unauthorized test run access' do
        get :show, params: { id: other_test_run.id }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'GET #edit' do
    context 'with regular user' do
      before { sign_in user }

      it 'returns success for own test run' do
        get :edit, params: { id: test_run.id }
        expect(response).to be_successful
      end

      it 'assigns test run' do
        get :edit, params: { id: test_run.id }
        expect(assigns(:test_run)).to eq(test_run)
      end
    end
  end

  describe 'PATCH #update' do
    let(:valid_params) do
      {
        id: test_run.id,
        test_run: {
          name: 'Updated Test Run',
          description: 'Updated description',
          environment: 'production'
        }
      }
    end

    let(:invalid_params) do
      {
        id: test_run.id,
        test_run: {
          name: '',
          description: 'Invalid update'
        }
      }
    end

    context 'with regular user' do
      before { sign_in user }

      context 'with valid parameters' do
        it 'updates the test run' do
          patch :update, params: valid_params
          test_run.reload
          expect(test_run.name).to eq('Updated Test Run')
        end

        it 'redirects to show page' do
          patch :update, params: valid_params
          expect(response).to redirect_to(automated_testing_result_path(test_run))
        end
      end

      context 'with invalid parameters' do
        it 'does not update the test run' do
          original_name = test_run.name
          patch :update, params: invalid_params
          test_run.reload
          expect(test_run.name).to eq(original_name)
        end

        it 'renders edit template' do
          patch :update, params: invalid_params
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with regular user' do
      before { sign_in user }

      it 'destroys the test run' do
        expect {
          delete :destroy, params: { id: test_run.id }
        }.to change(TestRun, :count).by(-1)
      end

      it 'redirects to test runs' do
        delete :destroy, params: { id: test_run.id }
        expect(response).to redirect_to(automated_testing_test_runs_path)
      end
    end
  end

  describe 'private methods' do
    let(:controller_instance) { described_class.new }

    before do
      allow(controller_instance).to receive(:current_user).and_return(user)
    end
  end
end
