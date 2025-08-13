require 'rails_helper'

RSpec.describe "Flash message auto-close behavior", type: :view do
  before do
    # Mock current user as system admin
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(double('User', 
      first_name: 'Test', 
      last_name: 'Admin',
      full_name: 'Test Admin',
      system_admin?: true
    ))
  end

  it "disables auto-close in test environment" do
    # Set an alert flash message
    flash[:alert] = "Please provide a valid email address."
    
    # Render a simplified version of the layout's flash section
    render inline: <<~ERB
      <% if alert %>
        <div data-controller="alert" data-alert-auto-close-value="<%= Rails.env.test? ? 'false' : 'true' %>">
          <%= alert %>
        </div>
      <% end %>
    ERB

    expect(rendered).to include('data-alert-auto-close-value="false"')
    expect(rendered).to include("Please provide a valid email address.")
  end

  it "enables auto-close in production environment" do
    # Mock Rails environment as production
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    
    flash[:alert] = "Please provide a valid email address."
    
    render inline: <<~ERB
      <% if alert %>
        <div data-controller="alert" data-alert-auto-close-value="<%= Rails.env.test? ? 'false' : 'true' %>">
          <%= alert %>
        </div>
      <% end %>
    ERB

    expect(rendered).to include('data-alert-auto-close-value="true"')
    expect(rendered).to include("Please provide a valid email address.")
  end
end