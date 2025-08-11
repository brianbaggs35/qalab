class AutomatedTesting::ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_system_admin
  before_action :set_test_run, only: [ :show, :edit, :update, :destroy ]

  def index
    @test_runs = policy_scope(TestRun)

    # Apply filters
    @test_runs = @test_runs.by_environment(params[:environment]) if params[:environment].present?
    @test_runs = @test_runs.by_status(params[:status]) if params[:status].present?

    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @test_runs = @test_runs.where("name ILIKE ? OR description ILIKE ?", search_term, search_term)
    end

    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @test_runs = @test_runs.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    @test_runs = @test_runs.recent.page(params[:page]).per(20)

    # Statistics
    all_test_runs = policy_scope(TestRun)
    @stats = {
      total: all_test_runs.count,
      completed: all_test_runs.where(status: "completed").count,
      failed: all_test_runs.where(status: "failed").count,
      pending: all_test_runs.where(status: "pending").count,
      processing: all_test_runs.where(status: "processing").count
    }

    # Environment options for filter
    @environments = policy_scope(TestRun).distinct.pluck(:environment).compact.sort
  end

  def show
    authorize @test_run
    @test_details = parse_test_details(@test_run)
  end

  def edit
    authorize @test_run
  end

  def update
    authorize @test_run

    if @test_run.update(test_run_params)
      redirect_to automated_testing_result_path(@test_run), notice: "Test run updated successfully!"
    else
      render :edit, alert: "Error updating test run: #{@test_run.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    authorize @test_run

    if @test_run.destroy
      redirect_to automated_testing_results_path, notice: "Test run deleted successfully!"
    else
      redirect_to automated_testing_results_path, alert: "Error deleting test run."
    end
  end

  private

  def set_test_run
    @test_run = TestRun.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to automated_testing_results_path, alert: "Test run not found."
  end

  def test_run_params
    params.require(:test_run).permit(:name, :description, :environment, :test_suite)
  end

  def ensure_not_system_admin
    redirect_to system_admin_dashboard_path if current_user.system_admin?
  end

  def parse_test_details(test_run)
    # This would parse the XML file and extract individual test details
    # For now, return sample data structure
    return [] if test_run.xml_file.blank?

    [
      {
        name: "TestLogin",
        class: "com.example.LoginTest",
        status: "passed",
        duration: "0.5s",
        message: nil
      },
      {
        name: "TestLogout",
        class: "com.example.LoginTest",
        status: "failed",
        duration: "0.3s",
        message: "Expected logout button to be visible"
      }
    ]
  end
end
