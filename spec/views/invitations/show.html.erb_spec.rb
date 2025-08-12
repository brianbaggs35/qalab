require 'rails_helper'

RSpec.describe "invitations/show.html.erb", type: :view do
  it "renders the show template" do
    render
    expect(rendered).to include("Invitations#show")
    expect(rendered).to include("Find me in app/views/invitations/show.html.erb")
  end
end
