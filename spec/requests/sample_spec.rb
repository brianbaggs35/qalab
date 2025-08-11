require 'rails_helper'

RSpec.describe "Home page", type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Welcome to QA Lab")
    end
  end
  
  describe "GET /home/index" do
    it "returns http success" do
      get "/home/index"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Welcome to QA Lab")
    end
  end
end