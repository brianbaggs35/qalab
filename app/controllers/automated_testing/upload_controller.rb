class AutomatedTesting::UploadController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_system_admin

  def index
    # Show upload page
    @test_run = TestRun.new
    @recent_uploads = policy_scope(TestRun).recent.limit(5)
    @upload_stats = {
      total_uploads: policy_scope(TestRun).count,
      this_month: policy_scope(TestRun).where(created_at: 1.month.ago..Time.current).count,
      success_rate: calculate_success_rate
    }
  end

  def create
    @test_run = current_user.test_runs.build(test_run_params)
    @test_run.organization = current_user.organizations.first # For now, use first org

    authorize @test_run

    if @test_run.save
      # Process the XML file in background (for now, synchronously)
      if @test_run.xml_file.present?
        @test_run.process_xml_file
      end

      redirect_to automated_testing_results_path, notice: "Test run uploaded and processed successfully!"
    else
      @recent_uploads = policy_scope(TestRun).recent.limit(5)
      @upload_stats = {
        total_uploads: policy_scope(TestRun).count,
        this_month: policy_scope(TestRun).where(created_at: 1.month.ago..Time.current).count,
        success_rate: calculate_success_rate
      }
      render :index, alert: "Error uploading test run: #{@test_run.errors.full_messages.join(', ')}"
    end
  end

  private

  def test_run_params
    params.require(:test_run).permit(:name, :description, :environment, :test_suite, :xml_file)
  end

  def ensure_not_system_admin
    redirect_to system_admin_dashboard_path if current_user.system_admin?
  end

  def calculate_success_rate
    test_runs = policy_scope(TestRun).where(status: "completed")
    return 0 if test_runs.empty?

    total_tests = test_runs.sum(&:total_tests)
    passed_tests = test_runs.sum(&:passed_tests)

    return 0 if total_tests == 0
    (passed_tests.to_f / total_tests * 100).round(2)
  end
end
