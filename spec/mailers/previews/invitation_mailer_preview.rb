# Preview all emails at http://localhost:3000/rails/mailers/invitation_mailer_mailer
class InvitationMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/invitation_mailer_mailer/invite_user
  def invite_user
    InvitationMailer.invite_user
  end

end
