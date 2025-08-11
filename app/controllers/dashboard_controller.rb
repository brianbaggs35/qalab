class DashboardController < ApplicationController
  def index
    # Sample data for dashboard charts (will be replaced with real data later)
    @total_users = User.count
    @total_organizations = Organization.count
    @user_registrations_by_day = User.group_by_day(:created_at, last: 30).count
    @organizations_by_day = Organization.group_by_day(:created_at, last: 30).count

    # Role distribution
    @system_admin_count = User.system_admins.count
    @regular_user_count = User.regular_users.count

    # Organization member distribution
    @organization_roles = OrganizationUser.group(:role).count
  end
end
