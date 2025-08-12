class InvitationMailer < ApplicationMailer
  def invite_user(invitation)
    @invitation = invitation
    @organization = invitation.organization
    @invited_by = invitation.invited_by
    @accept_url = accept_invitation_url(token: invitation.token)
    
    mail(
      to: @invitation.email,
      subject: "You're invited to join #{@organization.name} on QA Lab"
    )
  end
end
