class ManualTesting::TestCasesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_system_admin
  before_action :set_test_case, only: [:show, :edit, :update, :destroy]

  def index
    @test_cases = policy_scope(TestCase).includes(:user, :organization)
                                       .recent
                                       .page(params[:page])
                                       .per(20)
    
    # Filter options
    @test_cases = @test_cases.by_priority(params[:priority]) if params[:priority].present?
    @test_cases = @test_cases.by_category(params[:category]) if params[:category].present?
    @test_cases = @test_cases.by_status(params[:status]) if params[:status].present?
    
    # Stats
    all_test_cases = policy_scope(TestCase)
    @stats = {
      total: all_test_cases.count,
      draft: all_test_cases.by_status(:draft).count,
      ready: all_test_cases.by_status(:ready).count,
      approved: all_test_cases.by_status(:approved).count
    }
  end

  def show
    authorize @test_case
  end

  def new
    @test_case = TestCase.new
    authorize @test_case
  end

  def create
    @test_case = current_user.test_cases.build(test_case_params)
    @test_case.organization = current_user.organizations.first
    
    # Parse steps from JSON if provided
    if params[:test_case][:steps].present?
      begin
        @test_case.steps = JSON.parse(params[:test_case][:steps])
      rescue JSON::ParserError
        @test_case.steps = []
      end
    end
    
    # Set status based on which button was clicked
    if params[:draft]
      @test_case.status = 'draft'
    elsif @test_case.status.blank?
      @test_case.status = 'ready'
    end
    
    authorize @test_case

    if @test_case.save
      redirect_to manual_testing_test_cases_path, 
                  notice: "Test case '#{@test_case.title}' created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @test_case
  end

  def update
    authorize @test_case
    
    # Parse steps from JSON if provided
    if params[:test_case][:steps].present?
      begin
        @test_case.steps = JSON.parse(params[:test_case][:steps])
      rescue JSON::ParserError
        # Keep existing steps if parsing fails
      end
    end
    
    if @test_case.update(test_case_params)
      redirect_to manual_testing_test_case_path(@test_case), 
                  notice: "Test case '#{@test_case.title}' updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @test_case
    title = @test_case.title
    @test_case.destroy
    redirect_to manual_testing_test_cases_path, 
                notice: "Test case '#{title}' deleted successfully!"
  end

  private

  def set_test_case
    @test_case = policy_scope(TestCase).find(params[:id])
  end

  def test_case_params
    params.require(:test_case).permit(
      :title, :priority, :description, :expected_results, :notes,
      :category, :status, :preconditions, :estimated_duration, :tags
      # Note: steps is handled separately in the controller action
    )
  end

  def ensure_not_system_admin
    redirect_to system_admin_dashboard_path if current_user.system_admin?
  end
end
