class SystemAdmin::OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_system_admin
  before_action :set_organization, only: [ :show, :edit, :update, :destroy ]

  def index
    @organizations = Organization.includes(:users, :test_runs, :test_cases)
                                 .order(:created_at)
                                 .page(params[:page])
                                 .per(20)

    # Apply filters
    if params[:search].present?
      @organizations = @organizations.where("name ILIKE ? OR description ILIKE ?",
                                          "%#{params[:search]}%", "%#{params[:search]}%")
    end

    # Statistics
    @stats = {
      total: Organization.count,
      active: Organization.joins(:users).distinct.count,
      inactive: Organization.left_joins(:users).where(users: { id: nil }).count,
      total_users: User.joins(:organizations).distinct.count,
      total_test_runs: TestRun.count,
      total_test_cases: TestCase.count
    }
  end

  def show
    @organization_stats = {
      users_count: @organization.users.count,
      owners_count: @organization.owners.count,
      admins_count: @organization.admins.count,
      members_count: @organization.members.count,
      test_runs_count: @organization.test_runs.count,
      test_cases_count: @organization.test_cases.count,
      success_rate: @organization.success_rate,
      created_at: @organization.created_at
    }

    @recent_activity = {
      recent_test_runs: @organization.test_runs.includes(:user).order(created_at: :desc).limit(5),
      recent_test_cases: @organization.test_cases.includes(:user).order(created_at: :desc).limit(5),
      recent_users: @organization.users.order(:created_at).limit(5)
    }

    @users_by_role = @organization.organization_users.includes(:user).group_by(&:role)
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      # If a user_id is provided, make that user the owner
      if params[:owner_user_id].present?
        user = User.find(params[:owner_user_id])
        @organization.organization_users.create!(user: user, role: "owner")
      end

      redirect_to system_admin_organization_path(@organization),
                  notice: "Organization '#{@organization.name}' created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to system_admin_organization_path(@organization),
                  notice: "Organization '#{@organization.name}' updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @organization.users.any?
      redirect_to system_admin_organization_path(@organization),
                  alert: "Cannot delete organization with users. Remove all users first."
      return
    end

    name = @organization.name
    @organization.destroy
    redirect_to system_admin_organizations_path,
                notice: "Organization '#{name}' deleted successfully!"
  end

  # User management actions
  def add_user
    @organization = Organization.find(params[:id])
    user = User.find(params[:user_id])
    role = params[:role] || "member"

    if @organization.organization_users.exists?(user: user)
      redirect_to system_admin_organization_path(@organization),
                  alert: "User '#{user.full_name}' is already a member of this organization."
      return
    end

    @organization.organization_users.create!(user: user, role: role)
    redirect_to system_admin_organization_path(@organization),
                notice: "User '#{user.full_name}' added as #{role} successfully!"
  end

  def remove_user
    @organization = Organization.find(params[:id])
    user = User.find(params[:user_id])

    organization_user = @organization.organization_users.find_by(user: user)
    if organization_user
      # Check if user is the last owner
      if organization_user.role == "owner" && @organization.owners.count == 1
        redirect_to system_admin_organization_path(@organization),
                    alert: "Cannot remove the last owner. Add another owner first."
        return
      end

      organization_user.destroy
      redirect_to system_admin_organization_path(@organization),
                  notice: "User '#{user.full_name}' removed from organization successfully!"
    else
      redirect_to system_admin_organization_path(@organization),
                  alert: "User '#{user.full_name}' is not a member of this organization."
    end
  end

  def change_user_role
    @organization = Organization.find(params[:id])
    user = User.find(params[:user_id])
    new_role = params[:new_role]

    organization_user = @organization.organization_users.find_by(user: user)
    if organization_user
      # Check if changing last owner
      if organization_user.role == "owner" && new_role != "owner" && @organization.owners.count == 1
        redirect_to system_admin_organization_path(@organization),
                    alert: "Cannot change role of the last owner. Add another owner first."
        return
      end

      organization_user.update!(role: new_role)
      redirect_to system_admin_organization_path(@organization),
                  notice: "User '#{user.full_name}' role changed to #{new_role} successfully!"
    else
      redirect_to system_admin_organization_path(@organization),
                  alert: "User '#{user.full_name}' is not a member of this organization."
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :description, :settings)
  end

  def ensure_system_admin
    redirect_to root_path, alert: "Access denied." unless current_user.system_admin?
  end
end
