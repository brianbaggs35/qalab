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
    @test_run = current_user.test_runs.build(test_run_params.except(:xml_file))
    @test_run.organization = current_user.organizations.first # For now, use first org

    # Handle file upload and store content in xml_file field
    if params[:test_run][:xml_file].present?
      uploaded_file = params[:test_run][:xml_file]

      # Validate file type
      unless uploaded_file.content_type.in?([ "text/xml", "application/xml" ]) ||
             uploaded_file.original_filename.downcase.ends_with?(".xml")
        @test_run.errors.add(:xml_file, "must be an XML file")
      end

      # Validate file size (50MB limit)
      if uploaded_file.size > 50.megabytes
        @test_run.errors.add(:xml_file, "must be less than 50MB")
      end

      # Read file content and store it
      if @test_run.errors.empty?
        @test_run.xml_file = uploaded_file.read

        # Generate name from filename if not provided
        if @test_run.name.blank?
          base_name = File.basename(uploaded_file.original_filename, File.extname(uploaded_file.original_filename))
          @test_run.name = "#{base_name} - #{Time.current.strftime('%Y-%m-%d %H:%M')}"
        end
      end
    end

    authorize @test_run

    if @test_run.errors.empty? && @test_run.save
      # Process the XML file in background (for now, synchronously)
      if @test_run.xml_file.present?
        processed = @test_run.process_xml_file

        if processed
          redirect_to automated_testing_results_path, notice: "Test run uploaded and processed successfully! #{@test_run.total_tests} tests processed."
        else
          redirect_to automated_testing_results_path, alert: "Test run uploaded but failed to process XML. Please check the file format."
        end
      else
        redirect_to automated_testing_results_path, notice: "Test run created successfully!"
      end
    else
      @recent_uploads = policy_scope(TestRun).recent.limit(5)
      @upload_stats = {
        total_uploads: policy_scope(TestRun).count,
        this_month: policy_scope(TestRun).where(created_at: 1.month.ago..Time.current).count,
        success_rate: calculate_success_rate
      }
      render :index, status: :unprocessable_content
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
