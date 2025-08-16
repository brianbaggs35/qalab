require "rails_helper"

RSpec.describe SystemAdmin::DashboardController, type: :controller do
  let(:admin_user) { create(:user, :system_admin) }

  before do
    sign_in admin_user
  end

  describe "POST #test_smtp" do
    context "with valid SMTP settings" do
      before do
        allow(SystemSetting).to receive(:smtp_settings).and_return({
          "address" => "smtp.gmail.com",
          "port" => "587",
          "username" => "test@example.com"
        })
      end

      it "returns success when test email is sent" do
        allow(TestMailer).to receive_message_chain(:smtp_test_email, :deliver_now)

        post :test_smtp, format: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["message"]).to include("Test email sent successfully")
      end

      it "returns error when email delivery fails" do
        allow(TestMailer).to receive_message_chain(:smtp_test_email, :deliver_now).and_raise(StandardError.new("SMTP error"))

        post :test_smtp, format: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["message"]).to include("SMTP test failed")
      end
    end

    context "without SMTP settings" do
      before do
        allow(SystemSetting).to receive(:smtp_settings).and_return({})
      end

      it "returns error when SMTP is not configured" do
        post :test_smtp, format: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["message"]).to include("Please configure SMTP settings first")
      end
    end
  end
end
