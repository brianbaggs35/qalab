class Users::RegistrationsController < Devise::RegistrationsController
  # Skip Pundit authorization callbacks for Devise controllers
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  private

  def skip_pundit_authorization?
    true
  end

  def skip_authorization?
    true
  end
end