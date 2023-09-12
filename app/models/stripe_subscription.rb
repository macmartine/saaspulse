class StripeSubscription < ApplicationRecord
  belongs_to :stripe_customer

  def days_til_conversion
    2
  end
end
