require 'rails_helper'

RSpec.describe "system_admin/organizations/new.html.erb", type: :view do
  let(:organization) { build(:organization) }

  before do
    assign(:organization, organization)
  end

  it "renders the create organization form" do
    render
    expect(rendered).to include("Create New Organization")
    expect(rendered).to include("form")
  end

  it "displays required form fields" do
    render
    expect(rendered).to include("Organization Name")
    expect(rendered).to include("required")
  end

  it "shows form actions" do
    render
    expect(rendered).to include("Create Organization")
    expect(rendered).to include("Cancel")
  end

  it "displays breadcrumbs" do
    render
    expect(rendered).to include("Organizations")
    expect(rendered).to include("Create New")
  end

  it "shows initial settings section" do
    render
    expect(rendered).to include("Initial Settings")
    expect(rendered).to include("default settings")
  end

  it "displays info cards" do
    render
    expect(rendered).to include("What happens next?")
    expect(rendered).to include("Important Notes")
  end

  context "with validation errors" do
    before do
      organization.errors.add(:name, "can't be blank")
      assign(:organization, organization)
    end

    it "displays error messages" do
      render
      expect(rendered).to include("Error!")
      expect(rendered).to include("Name can&#39;t be blank")
    end
  end
end
