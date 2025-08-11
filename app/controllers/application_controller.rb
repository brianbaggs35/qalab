class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Devise parameter sanitization
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :redirect_system_admin, if: :user_signed_in?

  # Pundit authorization
  after_action :verify_authorized, except: :index, unless: :skip_authorization?
  after_action :verify_policy_scoped, only: :index, unless: :skip_authorization?

  # Handle Pundit authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Devise redirects
  def after_sign_in_path_for(resource)
    if resource.system_admin?
      system_admin_dashboard_path
    else
      dashboard_path
    end
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name ])
  end

  def current_organization
    @current_organization ||= current_user&.organizations&.first
  end
  helper_method :current_organization

  private

  def redirect_system_admin
    if current_user&.system_admin? && !request.path.start_with?("/system_admin") && !devise_controller?
      redirect_to system_admin_dashboard_path
    end
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referrer || root_path)
  end

  def skip_authorization?
    devise_controller? ||
    (controller_name == "home" && action_name == "index") ||
    (controller_name == "dashboard" && action_name == "index") ||
    (controller_name == "organizations" && action_name == "index") ||
    controller_path.start_with?("automated_testing") ||
    controller_path.start_with?("manual_testing") ||
    controller_path.start_with?("system_admin") ||
    (controller_name == "rails/health" && action_name == "show")
  end
end
