class TestMailer < ApplicationMailer
  def smtp_test_email(email)
    @email = email
    @timestamp = Time.current.strftime("%B %d, %Y at %I:%M %p")
    
    mail(
      to: email,
      subject: "QA Lab SMTP Test - #{@timestamp}"
    )
  end
end