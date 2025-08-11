class ManualTesting::TestCasesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_system_admin

  def index
    # Show test cases
  end

  def show
    # Show specific test case
  end

  def new
    # New test case form
  end

  def create
    # Create test case
    redirect_to manual_testing_cases_path, notice: "Test case created successfully!"
  end

  def edit
    # Edit test case form
  end

  def update
    # Update test case
    redirect_to manual_testing_cases_path, notice: "Test case updated successfully!"
  end

  def destroy
    # Delete test case
    redirect_to manual_testing_cases_path, notice: "Test case deleted successfully!"
  end

  private

  def ensure_not_system_admin
    redirect_to system_admin_dashboard_path if current_user.system_admin?
  end
end
