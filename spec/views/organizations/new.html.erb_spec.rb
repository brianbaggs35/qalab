require 'rails_helper'

RSpec.describe "organizations/new.html.erb", type: :view do
  let(:organization) { build(:organization) }

  before do
    assign(:organization, organization)
  end

  it "renders the organization form" do
    render
    expect(rendered).to include("Create Organization")
  end
end
