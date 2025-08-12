class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_onboarding_needed, except: [:complete]
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def welcome
    @user = current_user
  end

  def organization
    @organization = Organization.new
    @is_first_organization = Organization.count == 0
  end

  def create_organization
    @organization = Organization.new(organization_params)
    @is_first_organization = Organization.count == 0

    if @organization.save
      # Add the creator as owner
      @organization.organization_users.create!(
        user: current_user,
        role: "owner"
      )
      
      # Mark onboarding as complete
      current_user.update(onboarding_completed_at: Time.current)
      
      redirect_to onboarding_complete_path
    else
      render :organization, status: :unprocessable_entity
    end
  end

  def complete
    @organization = current_user.organizations.first
  end

  private

  def organization_params
    params.require(:organization).permit(:name)
  end

  def ensure_onboarding_needed
    # Skip onboarding if user already completed it or belongs to an organization
    if current_user.onboarding_completed_at.present? || current_user.organizations.exists?
      redirect_to dashboard_path
    end
  end
end