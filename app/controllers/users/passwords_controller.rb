class Users::PasswordsController < Devise::PasswordsController
  # Skip Pundit policies for this controller
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  protected

  def after_resetting_password_path_for(resource)
    signed_in_root_path(resource)
  end

  def after_sending_reset_password_instructions_path_for(resource_name)
    new_session_path(resource_name) if is_navigational_format?
  end
end