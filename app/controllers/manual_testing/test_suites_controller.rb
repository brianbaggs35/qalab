class ManualTesting::TestSuitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_test_suite, only: [:show, :edit, :update, :destroy]

  def index
    @test_suites = policy_scope(TestSuite).includes(:user, :organization)
                                          .recent
                                          .page(params[:page])
                                          .per(20)
    authorize TestSuite
  end

  def show
    authorize @test_suite
    @test_cases = @test_suite.test_cases.includes(:user).recent.page(params[:page]).per(10)
  end

  def new
    @test_suite = TestSuite.new
    authorize @test_suite
  end

  def create
    @test_suite = current_user.test_suites.build(test_suite_params)
    @test_suite.organization = current_user.organizations.first

    authorize @test_suite

    if @test_suite.save
      redirect_to manual_testing_test_suite_path(@test_suite),
                  notice: "Test suite '#{@test_suite.name}' created successfully!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @test_suite
  end

  def update
    authorize @test_suite

    if @test_suite.update(test_suite_params)
      redirect_to manual_testing_test_suite_path(@test_suite),
                  notice: "Test suite '#{@test_suite.name}' updated successfully!"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @test_suite
    name = @test_suite.name
    @test_suite.destroy
    redirect_to manual_testing_test_suites_path,
                notice: "Test suite '#{name}' deleted successfully!"
  end

  private

  def set_test_suite
    @test_suite = policy_scope(TestSuite).find(params[:id])
  end

  def test_suite_params
    params.require(:test_suite).permit(:name, :description)
  end
end
