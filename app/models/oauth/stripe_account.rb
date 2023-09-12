class Oauth::StripeAccount < ApplicationRecord
  include Oauth::StripeAccounts::Base

  def name
    data.dig("extra", "extra_info", "business_profile", "name").presence || "Stripe Account"
  rescue
    "Stripe Account"
  end

end
