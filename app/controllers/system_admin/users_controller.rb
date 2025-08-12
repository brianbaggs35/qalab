class SystemAdmin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_system_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.includes(:organizations)
                 .order(:created_at)
                 .page(params[:page])
                 .per(20)

    # Apply filters
    @users = @users.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", 
                          "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @users = @users.where(role: params[:role]) if params[:role].present?

    # Statistics
    @stats = {
      total: User.count,
      system_admins: User.system_admins.count,
      regular_users: User.regular_users.count,
      confirmed: User.confirmed.count,
      unconfirmed: User.unconfirmed.count,
      locked: User.where.not(locked_at: nil).count
    }
  end

  def show
    @user_stats = {
      organizations_count: @user.organizations.count,
      test_runs_count: @user.test_runs.count,
      test_cases_count: @user.test_cases.count,
      last_sign_in: @user.last_sign_in_at,
      sign_in_count: @user.sign_in_count
    }
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      redirect_to system_admin_user_path(@user), 
                  notice: "User '#{@user.full_name}' created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Handle password updates specially
    if user_params[:password].blank?
      update_params = user_params.except(:password, :password_confirmation)
    else
      update_params = user_params
    end

    if @user.update(update_params)
      redirect_to system_admin_user_path(@user), 
                  notice: "User '#{@user.full_name}' updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to system_admin_users_path, 
                  alert: "You cannot delete your own account!"
      return
    end

    if @user.organizations.any?
      redirect_to system_admin_user_path(@user), 
                  alert: "Cannot delete user who belongs to organizations. Remove from organizations first."
      return
    end

    name = @user.full_name
    @user.destroy
    redirect_to system_admin_users_path, 
                notice: "User '#{name}' deleted successfully!"
  end

  # Additional admin actions
  def lock
    @user = User.find(params[:id])
    @user.lock_access!
    redirect_to system_admin_user_path(@user), 
                notice: "User account locked successfully!"
  end

  def unlock
    @user = User.find(params[:id])
    @user.unlock_access!
    redirect_to system_admin_user_path(@user), 
                notice: "User account unlocked successfully!"
  end

  def confirm
    @user = User.find(params[:id])
    @user.confirm unless @user.confirmed?
    redirect_to system_admin_user_path(@user), 
                notice: "User account confirmed successfully!"
  end

  def resend_confirmation
    @user = User.find(params[:id])
    @user.send_confirmation_instructions
    redirect_to system_admin_user_path(@user), 
                notice: "Confirmation email sent successfully!"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :password, :password_confirmation, 
      :role, :confirmed_at
    )
  end

  def ensure_system_admin
    redirect_to root_path, alert: "Access denied." unless current_user.system_admin?
  end
end