class SystemAdmin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_system_admin

  def index
    # System admin dashboard
  end

  private

  def ensure_system_admin
    redirect_to root_path, alert: "Access denied." unless current_user.system_admin?
  end
end
