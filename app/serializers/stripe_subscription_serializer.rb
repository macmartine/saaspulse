class StripeSubscriptionSerializer < ActiveModel::Serializer

  attribute :email
  attributes :num_days_til_conversion, :price_after_discount

  def email
    object.stripe_customer.email
  end

  def num_days_til_conversion
    object.days_til_conversion
  end
end
