require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "Pundit authorization skipping" do
    let(:controller_instance) { described_class.new }

    it "skips pundit authorization" do
      expect(controller_instance.send(:skip_pundit_authorization?)).to be true
    end

    it "skips authorization" do
      expect(controller_instance.send(:skip_authorization?)).to be true
    end
  end
end
