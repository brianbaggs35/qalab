require 'rails_helper'

RSpec.describe "Invitations", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/invitations/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/invitations/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/invitations/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/invitations/show"
      expect(response).to have_http_status(:success)
    end
  end

end
