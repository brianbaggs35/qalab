class AutomatedTesting::ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_system_admin

  def index
    # Show test results
  end

  def show
    # Show detailed test result
  end

  private

  def ensure_not_system_admin
    redirect_to system_admin_dashboard_path if current_user.system_admin?
  end
end
