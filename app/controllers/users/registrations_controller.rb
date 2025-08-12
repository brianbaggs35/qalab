class Users::RegistrationsController < Devise::RegistrationsController
  # Skip Pundit authorization callbacks for Devise controllers
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  before_action :configure_sign_up_params, only: [:create]
  before_action :validate_invitation_token, only: [:create]

  protected

  def sign_up(resource_name, resource)
    super(resource_name, resource)
    
    # Accept the invitation if registration is successful
    if resource.persisted? && @invitation
      @invitation.accept!
      
      # Add user to organization with the invited role
      organization_user = OrganizationUser.create!(
        user: resource,
        organization: @invitation.organization,
        role: @invitation.role
      )
    end
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :invitation_token])
  end

  def validate_invitation_token
    invitation_token = params[:user][:invitation_token]
    
    if invitation_token.blank?
      flash[:alert] = "Sign ups are by invitation only. Please enter your invitation code."
      redirect_to new_user_registration_path
      return
    end

    @invitation = Invitation.find_valid_invitation(invitation_token)
    
    unless @invitation
      flash[:alert] = "Invalid or expired invitation code. Please check your invitation email or contact support."
      redirect_to new_user_registration_path
      return
    end

    # Validate email matches invitation
    user_email = params[:user][:email]
    if user_email != @invitation.email
      flash[:alert] = "Email address must match the invitation. Expected: #{@invitation.email}"
      redirect_to new_user_registration_path
      return
    end
  end

  def skip_pundit_authorization?
    true
  end

  def skip_authorization?
    true
  end
end
