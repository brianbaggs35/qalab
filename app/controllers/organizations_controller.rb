class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :show ]

  def index
    @organizations = policy_scope(Organization)
  end

  def show
    authorize @organization
  end

  def new
    @organization = Organization.new
    authorize @organization
  end

  def create
    @organization = Organization.new(organization_params)
    authorize @organization

    if @organization.save
      # Add the creator as owner
      @organization.organization_users.create!(
        user: current_user,
        role: "owner"
      )
      redirect_to @organization, notice: "Organization was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, settings: {})
  end
end
