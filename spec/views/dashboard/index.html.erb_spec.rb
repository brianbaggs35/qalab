require 'rails_helper'

RSpec.describe "dashboard/index.html.erb", type: :view do
  let(:user) { create(:user, first_name: "John") }

  before do
    # Simulate signed in user
    allow(view).to receive(:current_user).and_return(user)

    # Set up required instance variables
    assign(:test_run_stats, {
      total: 10,
      completed: 7,
      failed: 2
    })
    assign(:overall_success_rate, 70)
    assign(:recent_test_runs, [])
    assign(:test_runs_by_environment, {})
  end

  it "renders the dashboard title" do
    render
    expect(rendered).to include("Dashboard")
  end

  it "displays the user's first name" do
    render
    expect(rendered).to include("Welcome back, John!")
  end

  it "shows test run statistics" do
    render
    expect(rendered).to include("10") # total
    expect(rendered).to include("7")  # completed
    expect(rendered).to include("2")  # failed
    expect(rendered).to include("70%") # success rate
  end

  it "includes navigation links" do
    render
    expect(rendered).to include("Upload Tests")
    expect(rendered).to include("View Results")
  end

  it "displays quick action cards" do
    render
    expect(rendered).to include("Upload Test Results")
    expect(rendered).to include("View Test Results")
    expect(rendered).to include("Manual Test Cases")
  end

  context "when there are recent test runs" do
    let!(:test_run) { create(:test_run, name: "Test Suite", environment: "staging", status: "completed") }

    before do
      assign(:recent_test_runs, [ test_run ])
    end

    it "displays the recent test runs table" do
      render
      expect(rendered).to include("Recent Test Runs")
      expect(rendered).to include("Test Suite")
      expect(rendered).to include("staging")
      expect(rendered).to include("Completed")
    end
  end

  context "when there are no recent test runs" do
    it "displays empty state message" do
      render
      expect(rendered).to include("No Test Runs Yet")
      expect(rendered).to include("Upload your first test results")
    end
  end

  context "when there are test runs by environment" do
    before do
      assign(:test_runs_by_environment, { "production" => 5, "staging" => 3 })
    end

    it "displays the environment chart section" do
      render
      expect(rendered).to include("Test Runs by Environment")
    end
  end

  it "sets the page title" do
    render
    expect(view.content_for(:title)).to eq("Dashboard")
  end
end
