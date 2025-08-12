require 'rails_helper'

RSpec.describe "invitations/create.html.erb", type: :view do
  it "renders the create template" do
    render
    expect(rendered).to include("Invitations#create")
    expect(rendered).to include("Find me in app/views/invitations/create.html.erb")
  end
end
