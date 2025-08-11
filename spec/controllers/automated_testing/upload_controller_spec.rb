require 'rails_helper'

RSpec.describe AutomatedTesting::UploadController, type: :controller do
  let(:user) { create(:user) }
  let(:system_admin) { create(:user, :system_admin) }

  describe "GET #index" do
    context "with regular user" do
      before { sign_in user }

      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "with system admin" do
      before { sign_in system_admin }

      it "redirects to system admin dashboard" do
        get :index
        expect(response).to redirect_to(system_admin_dashboard_path)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST #create" do
    before { sign_in user }

    context "with valid file" do
      let(:test_file) { fixture_file_upload('test_file.xml', 'application/xml') }

      it "redirects with success notice" do
        post :create, params: { test_file: test_file }
        expect(response).to redirect_to(automated_testing_upload_path)
        expect(flash[:notice]).to eq("File uploaded successfully!")
      end
    end

    context "without file" do
      it "redirects with error alert" do
        post :create, params: {}
        expect(response).to redirect_to(automated_testing_upload_path)
        expect(flash[:alert]).to eq("Please select a file to upload.")
      end
    end
  end
end