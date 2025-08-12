require 'rails_helper'

RSpec.describe "invitations/index.html.erb", type: :view do
  let(:organization) { create(:organization, name: "Test Organization") }
  let(:user) { create(:user) }
  let(:invitations) do
    [
      create(:invitation, organization: organization, email: "user1@example.com"),
      create(:invitation, organization: organization, email: "user2@example.com")
    ]
  end

  before do
    assign(:organization, organization)
    assign(:invitations, invitations)
    allow(view).to receive(:current_user).and_return(user)
  end

  it "displays the organization name" do
    render
    expect(rendered).to include("Test Organization")
  end

  it "displays invitation emails" do
    render
    expect(rendered).to include("user1@example.com")
    expect(rendered).to include("user2@example.com")
  end
end
