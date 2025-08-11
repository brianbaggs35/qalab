class SystemAdmin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_system_admin

  def index
    # System-wide statistics
    @total_users = User.count
    @total_organizations = Organization.count
    @total_test_runs = TestRun.count
    @system_admins_count = User.system_admins.count

    # Growth metrics (last 30 days)
    @new_users_this_month = User.where(created_at: 30.days.ago..Time.current).count
    @new_organizations_this_month = Organization.where(created_at: 30.days.ago..Time.current).count
    @new_test_runs_this_month = TestRun.where(created_at: 30.days.ago..Time.current).count

    # User activity charts
    @user_registrations_by_day = User.group_by_day(:created_at, last: 30).count
    @organizations_by_day = Organization.group_by_day(:created_at, last: 30).count
    @test_runs_by_day = TestRun.group_by_day(:created_at, last: 30).count

    # System health metrics
    @test_runs_by_status = TestRun.group(:status).count
    @organizations_by_user_count = Organization.joins(:users).group("organizations.name").count.sort_by { |_, count| -count }.first(10)

    # Platform usage statistics
    @top_environments = TestRun.group(:environment).count.sort_by { |_, count| -count }.first(5)
    @monthly_activity = TestRun.group_by_month(:created_at, last: 12).count

    # System performance
    @average_tests_per_run = TestRun.where(status: "completed").average("(results_summary->>'total_tests')::float").to_f.round(2)
    @overall_success_rate = calculate_system_success_rate

    # Recent activity
    @recent_organizations = Organization.order(created_at: :desc).limit(5)
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_test_runs = TestRun.includes(:organization, :user).order(created_at: :desc).limit(10)

    # User distribution by organization role
    @organization_role_distribution = OrganizationUser.group(:role).count

    # Storage and performance metrics
    @database_size_mb = calculate_database_size
    @average_xml_size_kb = calculate_average_xml_size
  end

  private

  def ensure_system_admin
    redirect_to root_path, alert: "Access denied." unless current_user.system_admin?
  end

  def calculate_system_success_rate
    completed_runs = TestRun.where(status: "completed")
    return 0 if completed_runs.empty?

    total_tests = completed_runs.sum { |run| run.total_tests }
    passed_tests = completed_runs.sum { |run| run.passed_tests }

    return 0 if total_tests == 0
    (passed_tests.to_f / total_tests * 100).round(2)
  end

  def calculate_database_size
    # Simplified database size calculation
    # In production, this would query actual database size
    begin
      result = ActiveRecord::Base.connection.execute("SELECT pg_database_size(current_database()) / 1024 / 1024 AS size_mb")
      result.first["size_mb"].to_f.round(2)
    rescue
      0.0
    end
  end

  def calculate_average_xml_size
    # Calculate average XML file size in KB
    test_runs_with_xml = TestRun.where.not(xml_file: [ nil, "" ])
    return 0 if test_runs_with_xml.empty?

    total_size = test_runs_with_xml.sum { |run| run.xml_file.bytesize }
    (total_size.to_f / test_runs_with_xml.count / 1024).round(2)
  end
end
