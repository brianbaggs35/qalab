class AutomatedTesting::UploadController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_not_system_admin

  def index
    # Show upload page
  end

  def create
    # Handle file upload
    if params[:test_file].present?
      # TODO: Process XML file upload
      redirect_to automated_testing_upload_path, notice: "File uploaded successfully!"
    else
      redirect_to automated_testing_upload_path, alert: "Please select a file to upload."
    end
  end

  private

  def ensure_not_system_admin
    redirect_to system_admin_dashboard_path if current_user.system_admin?
  end
end
