require 'rails_helper'

RSpec.describe "system_admin/organizations/show.html.erb", type: :view do
  let(:organization) { create(:organization, name: "Test Organization") }
  let(:user1) { create(:user, :confirmed, :onboarded) }
  let(:user2) { create(:user, :confirmed, :onboarded) }

  before do
    # Create organization users with different roles
    create(:organization_user, user: user1, organization: organization, role: 'owner')
    create(:organization_user, user: user2, organization: organization, role: 'admin')

    assign(:organization, organization)
    assign(:organization_stats, {
      users_count: 2,
      owners_count: 1,
      admins_count: 1,
      members_count: 0,
      test_runs_count: 0,
      test_cases_count: 0,
      success_rate: 0.0,
      created_at: organization.created_at
    })
    assign(:recent_activity, {
      recent_test_runs: [],
      recent_test_cases: [],
      recent_users: []
    })
    assign(:users_by_role, {
      'owner' => [ OrganizationUser.find_by(user: user1, organization: organization) ],
      'admin' => [ OrganizationUser.find_by(user: user2, organization: organization) ]
    })
  end

  it "renders the organization name" do
    render
    expect(rendered).to include("Test Organization")
  end

  it "displays organization statistics" do
    render
    expect(rendered).to include("Total Users")
    expect(rendered).to include("Test Runs")
    expect(rendered).to include("Test Cases")
    expect(rendered).to include("Success Rate")
  end

  it "shows organization information section" do
    render
    expect(rendered).to include("Organization Information")
    expect(rendered).to include("Name")
    expect(rendered).to include("Created")
    expect(rendered).to include("Last Updated")
  end

  it "displays organization members" do
    render
    expect(rendered).to include("Organization Members")
    expect(rendered).to include(user1.email)
    expect(rendered).to include(user2.email)
  end

  it "shows edit and delete buttons" do
    render
    expect(rendered).to include("Edit Organization")
    # Delete button only shows if no users
  end

  it "displays breadcrumbs" do
    render
    expect(rendered).to include("Organizations")
    expect(rendered).to include("Test Organization")
  end

  context "when organization has no users" do
    let(:empty_organization) { create(:organization, name: "Empty Org") }

    before do
      assign(:organization, empty_organization)
      assign(:organization_stats, {
        users_count: 0,
        owners_count: 0,
        admins_count: 0,
        members_count: 0,
        test_runs_count: 0,
        test_cases_count: 0,
        success_rate: 0.0,
        created_at: empty_organization.created_at
      })
      assign(:recent_activity, {
        recent_test_runs: [],
        recent_test_cases: [],
        recent_users: []
      })
      assign(:users_by_role, {})
    end

    it "shows delete button for empty organization" do
      render
      expect(rendered).to include("Delete Organization")
    end
  end
end
