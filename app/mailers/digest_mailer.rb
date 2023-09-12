class DigestMailer < ApplicationMailer

  layout false
  default from: 'mac@saaspulse.io'

  def digest(content, email)
    @content = content
    # @content = StripeReport.new(nil)
    mail(to: email, subject: 'SaaS Pulse digest for Aware')
  end
end
