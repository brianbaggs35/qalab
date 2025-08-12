class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitation, only: [:show, :destroy]
  before_action :set_organization, only: [:index, :new, :create]
  
  def index
    authorize Invitation
    @invitations = policy_scope(Invitation)
                    .where(organization: @organization)
                    .includes(:invited_by)
                    .order(created_at: :desc)
                    .page(params[:page])
                    .per(25)
  end

  def new
    @invitation = Invitation.new
    authorize @invitation
  end

  def create
    @invitation = @organization.invitations.build(invitation_params)
    @invitation.invited_by = current_user
    
    authorize @invitation
    
    if @invitation.save
      # TODO: Send invitation email
      InvitationMailer.invite_user(@invitation).deliver_later
      
      redirect_to invitations_path, 
        notice: "Invitation sent to #{@invitation.email} successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @invitation
  end

  def destroy
    authorize @invitation
    
    if @invitation.destroy
      redirect_to invitations_path, notice: "Invitation cancelled successfully."
    else
      redirect_to invitations_path, alert: "Failed to cancel invitation."
    end
  end

  # Accept invitation via token (public endpoint)
  def accept
    @invitation = Invitation.find_valid_invitation(params[:token])
    
    unless @invitation
      redirect_to new_user_registration_path, 
        alert: "Invalid or expired invitation link."
      return
    end

    # If user is already signed in with a different email
    if user_signed_in? && current_user.email != @invitation.email
      sign_out current_user
      flash[:notice] = "Please sign up with the invited email address: #{@invitation.email}"
    end

    # If user is already signed in with the correct email, just accept the invitation
    if user_signed_in? && current_user.email == @invitation.email
      @invitation.accept!
      
      OrganizationUser.create!(
        user: current_user,
        organization: @invitation.organization,
        role: @invitation.role
      )
      
      redirect_to dashboard_path, 
        notice: "Welcome to #{@invitation.organization.name}!"
      return
    end

    # Redirect to sign up with invitation token pre-filled
    redirect_to new_user_registration_path(invitation_token: @invitation.token)
  end

  private

  def set_invitation
    @invitation = Invitation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to invitations_path, alert: "Invitation not found."
  end

  def set_organization
    # For now, use the first organization the user belongs to
    # This will be improved in the multi-organization phase
    @organization = current_user.organizations.first
    
    unless @organization
      redirect_to dashboard_path, alert: "You must belong to an organization to manage invitations."
    end
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end
end
