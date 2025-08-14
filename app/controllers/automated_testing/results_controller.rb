class AutomatedTesting::ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_system_admin
  before_action :set_test_run, only: [ :show, :edit, :update, :destroy ]

  def index
    @test_runs = policy_scope(TestRun).includes(:test_results)

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

    # Pagination with configurable page size
    per_page = [ params[:per_page].to_i, 25 ].max
    per_page = [ per_page, 100 ].min  # Cap at 100
    @test_runs = @test_runs.recent.page(params[:page]).per(per_page)

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

    # Per page options
    @per_page_options = [ 25, 50, 100 ]
    @current_per_page = per_page
  end

  def show
    authorize @test_run
    @test_results = @test_run.test_results.includes(:test_run)
                            .page(params[:page])
                            .per(params[:per_page] || 25)

    # Apply test result filters if present
    if params[:test_search].present?
      search_term = "%#{params[:test_search]}%"
      @test_results = @test_results.where("name ILIKE ? OR classname ILIKE ?", search_term, search_term)
    end

    if params[:test_status].present?
      @test_results = @test_results.where(status: params[:test_status])
    end
  end

  def test_result
    @test_run = TestRun.find(params[:id])
    authorize @test_run
    @test_result = @test_run.test_results.find(params[:test_result_id])

    render json: {
      id: @test_result.id,
      name: @test_result.name,
      classname: @test_result.classname,
      status: @test_result.status,
      time: @test_result.time,
      failure_message: @test_result.failure_message,
      failure_type: @test_result.failure_type,
      failure_stacktrace: @test_result.failure_stacktrace,
      system_out: @test_result.system_out,
      system_err: @test_result.system_err,
      test_run_name: @test_run.name
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Test result not found" }, status: :not_found
  end

  def edit
    authorize @test_run
  end

  def update
    authorize @test_run

    if @test_run.update(test_run_params)
      respond_to do |format|
        format.html { redirect_to automated_testing_result_path(@test_run), notice: "Test run updated successfully!" }
        format.json { render json: { success: true, message: "Test run updated successfully!" } }
      end
    else
      respond_to do |format|
        format.html { render :edit, alert: "Error updating test run: #{@test_run.errors.full_messages.join(', ')}" }
        format.json { render json: { success: false, errors: @test_run.errors.full_messages } }
      end
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
    params.require(:test_run).permit(:name, :description, :environment, :test_suite, :status)
  end

  def ensure_not_system_admin
    redirect_to system_admin_dashboard_path if current_user.system_admin?
  end
end
