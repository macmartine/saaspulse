class StripeSubscription < ApplicationRecord
  belongs_to :stripe_customer

  def days_til_conversion
    (trial_end.to_date - DateTime.now.utc.to_date).to_i
  end
end
