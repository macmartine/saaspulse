class DigestMailer < ApplicationMailer

  layout false
  default from: 'mac@saaspulse.io'

  def digest(content, team_name, email)
    @content = content
    @team_name = team_name
    mail(to: email, subject: 'SaaS Pulse digest for ' + team_name)
  end

  def test
    mail(to: 'mac@macmartine.com', subject: 'Test email sent for SaaSPulse')
  end
end
