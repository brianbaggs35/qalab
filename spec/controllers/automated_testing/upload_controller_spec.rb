require 'rails_helper'

RSpec.describe AutomatedTesting::UploadController, type: :controller do
  include ActionDispatch::TestProcess::FixtureFile

  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, role: 'system_admin') }

  before do
    create(:organization_user, organization: organization, user: user, role: 'member')
  end

  describe 'GET #index' do
    context 'with regular user' do
      before { sign_in user }

      it 'returns success' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns a new test run' do
        get :index
        expect(assigns(:test_run)).to be_a_new(TestRun)
      end

      it 'assigns recent uploads' do
        create(:test_run, organization: organization, user: user)
        get :index
        expect(assigns(:recent_uploads)).to be_present
      end

      it 'assigns upload stats' do
        get :index
        expect(assigns(:upload_stats)).to include(:total_uploads, :this_month, :success_rate)
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

  describe 'POST #create' do
    let(:xml_content) { '<testsuites><testsuite name="Test" tests="10"><testcase name="test1"></testcase></testsuite></testsuites>' }
    let(:uploaded_file) do
      fixture_file_upload(Rails.root.join('spec', 'fixtures', 'test_results.xml'), 'application/xml')
    end

    let(:valid_params) do
      {
        test_run: {
          name: 'Sample Test Run',
          description: 'A test run for testing',
          environment: 'staging',
          test_suite: 'smoke_tests',
          xml_file: uploaded_file
        }
      }
    end

    let(:invalid_params) do
      {
        test_run: {
          name: '',
          description: 'Invalid test run'
          # No xml_file, which should make it invalid since name will be empty
        }
      }
    end

    context 'with regular user' do
      before { sign_in user }

      context 'with valid parameters' do
        it 'creates a new test run' do
          expect {
            post :create, params: valid_params
          }.to change(TestRun, :count).by(1)
        end

        it 'assigns the test run to the current user' do
          post :create, params: valid_params
          expect(TestRun.last.user).to eq(user)
        end

        it 'redirects with success message' do
          post :create, params: valid_params
          expect(response).to redirect_to(automated_testing_results_path)
          expect(flash[:notice]).to include('successfully')
        end
      end

      context 'with invalid parameters' do
        it 'does not create a test run' do
          expect {
            post :create, params: invalid_params
          }.not_to change(TestRun, :count)
        end

        it 'renders the index template with unprocessable_content status' do
          post :create, params: invalid_params
          expect(response).to render_template(:index)
          expect(response).to have_http_status(:unprocessable_content)
        end

        it 'handles TestNG XML files correctly' do
          testng_file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'testng_results.xml'), 'application/xml')
          testng_params = valid_params.merge(test_run: valid_params[:test_run].merge(xml_file: testng_file))

          expect {
            post :create, params: testng_params
          }.to change(TestRun, :count).by(1)

          test_run = TestRun.last
          expect(test_run.xml_file).to include('testng-results')
        end

        it 'validates file size limit' do
          allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(51.megabytes)

          post :create, params: valid_params
          expect(assigns(:test_run).errors[:xml_file]).to include('must be less than 50MB')
        end

        it 'validates XML file content type' do
          text_file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test_file.txt'), 'text/plain')
          invalid_params = valid_params.merge(test_run: valid_params[:test_run].merge(xml_file: text_file))

          post :create, params: invalid_params
          expect(assigns(:test_run).errors[:xml_file]).to include('must be an XML file')
        end
      end
    end

    context 'with system admin' do
      before { sign_in system_admin }

      it 'redirects to system admin dashboard' do
        post :create, params: valid_params
        expect(response).to redirect_to(system_admin_dashboard_path)
      end
    end
  end
end
