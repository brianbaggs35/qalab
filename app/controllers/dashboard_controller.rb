class DashboardController < ApplicationController
  before_action :redirect_to_onboarding_if_needed

  def index
    # Redirect system admins to their own dashboard
    redirect_to system_admin_dashboard_path and return if current_user.system_admin?

    # Get user's organizations
    user_organizations = current_user.organizations

    # Basic statistics
    @total_users = User.count
    @total_organizations = Organization.count
    @user_registrations_by_day = User.group_by_day(:created_at, last: 30).count
    @organizations_by_day = Organization.group_by_day(:created_at, last: 30).count

    # Role distribution
    @system_admin_count = User.system_admins.count
    @regular_user_count = User.regular_users.count

    # Organization member distribution
    @organization_roles = OrganizationUser.group(:role).count

    # Test run statistics for user's organizations
    user_test_runs = TestRun.joins(:organization).where(organization: user_organizations)

    @test_run_stats = {
      total: user_test_runs.count,
      completed: user_test_runs.where(status: "completed").count,
      failed: user_test_runs.where(status: "failed").count,
      pending: user_test_runs.where(status: "pending").count,
      processing: user_test_runs.where(status: "processing").count
    }

    # Test results over time (last 30 days)
    @test_runs_by_day = user_test_runs.group_by_day(:created_at, last: 30).count
    @test_results_by_status = user_test_runs.group(:status).group_by_day(:created_at, last: 30).count

    # Success rate over time
    completed_runs = user_test_runs.where(status: "completed").includes(:organization)
    @success_rate_by_day = completed_runs.group_by_day(:created_at, last: 30).group("DATE(test_runs.created_at)").average("(results_summary->>'passed')::float / NULLIF((results_summary->>'total_tests')::float, 0) * 100")

    # Test environments distribution
    @test_runs_by_environment = user_test_runs.group(:environment).count

    # Recent activity
    @recent_test_runs = user_test_runs.recent.limit(5).includes(:user, :organization)

    # Calculate overall success rate for user's organizations
    @overall_success_rate = calculate_overall_success_rate(user_organizations)

    # Monthly trends
    @monthly_test_volume = user_test_runs.group_by_month(:created_at, last: 12).count
    @monthly_success_rates = calculate_monthly_success_rates(user_test_runs)
  end

  private

  def calculate_overall_success_rate(organizations)
    return 0 if organizations.empty?

    total_tests = 0
    passed_tests = 0

    organizations.each do |org|
      completed_runs = org.test_runs.where(status: "completed")
      completed_runs.each do |run|
        total_tests += run.total_tests
        passed_tests += run.passed_tests
      end
    end

    return 0 if total_tests == 0
    (passed_tests.to_f / total_tests * 100).round(2)
  end

  def calculate_monthly_success_rates(test_runs)
    monthly_rates = {}

    (0..11).each do |months_ago|
      start_date = months_ago.months.ago.beginning_of_month
      end_date = months_ago.months.ago.end_of_month

      month_runs = test_runs.where(created_at: start_date..end_date, status: "completed")

      total_tests = month_runs.sum(&:total_tests)
      passed_tests = month_runs.sum(&:passed_tests)

      rate = total_tests > 0 ? (passed_tests.to_f / total_tests * 100).round(2) : 0
      monthly_rates[start_date.strftime("%Y-%m")] = rate
    end

    monthly_rates
  end

  def redirect_to_onboarding_if_needed
    if current_user.needs_onboarding?
      redirect_to onboarding_welcome_path
    end
  end
end
