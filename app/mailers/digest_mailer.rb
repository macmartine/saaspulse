class DigestMailer < ApplicationMailer

  layout false
  default from: 'mac@saaspulse.io'

  def digest(content, email)
    @content = content
    mail(to: email, subject: 'SaaS Pulse digest for Aware')
  end

  def test
    mail(to: 'mac@macmartine.com', subject: 'Test email sent for SaaSPulse')
  end
end
