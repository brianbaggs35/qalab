require 'rails_helper'

RSpec.describe "Home page", type: :request do
  describe "GET /" do
    it "redirects unauthenticated users to sign in" do
      get "/"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated users" do
      sign_in create(:user)
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /home/index" do
    it "redirects unauthenticated users to sign in" do
      get "/home/index"
      expect(response).to redirect_to(new_user_session_path)
    end

    it "allows authenticated users" do
      sign_in create(:user)
      get "/home/index"
      expect(response).to have_http_status(:success)
    end
  end
end
