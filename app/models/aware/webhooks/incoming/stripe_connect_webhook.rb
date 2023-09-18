class Aware::Webhooks::Incoming::StripeConnectWebhook < ApplicationRecord
  include Aware::Webhooks::Incoming::Webhook
  include Aware::Webhooks::Incoming::Base


  def process
    case type
    when "customer.discount.created"
    when "customer.discount.updated"
    when "customer.discount.deleted"
    when "customer.created", "customer.updated"
      update_customer(object)
    when "checkout.session.completed"
      # We may not know the stripe_subscription_id of the Subscription in question, so set it now.
      # While it is often set by the user navigating to subscriptions#refresh following a completed
      # Stripe Checkout Session, sometimes the user fails to navigate there.
      subscription = StripeSubscription.find_by(id: data.dig("data", "object", "client_reference_id"))
      subscription.update(subscription_id: data.dig("data", "object", "subscription"))
    when "customer.subscription.created", "customer.subscription.updated"
      update_subscription(object)
    end
  end

  def object
    data.dig("data", "object")
  end

  def type
    data.dig("type")
  end

end
