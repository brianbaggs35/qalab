require 'rails_helper'

RSpec.describe "organizations/show.html.erb", type: :view do
  let(:organization) { create(:organization, name: "Test Organization") }
  let(:user1) { create(:user, :confirmed, :onboarded) }
  let(:user2) { create(:user, :confirmed, :onboarded) }

  before do
    # Create organization users with different roles
    create(:organization_user, user: user1, organization: organization, role: 'owner')
    create(:organization_user, user: user2, organization: organization, role: 'admin')

    assign(:organization, organization)
  end

  it "renders the organization name" do
    render
    expect(rendered).to include("Test Organization")
  end

  it "displays organization information" do
    render
    expect(rendered).to include("Organization Information")
    expect(rendered).to include("Created")
    expect(rendered).to include("Total Members")
  end

  it "shows member counts" do
    render
    expect(rendered).to include("Owners")
    expect(rendered).to include("Admins")
    expect(rendered).to include("Members")
  end
end
