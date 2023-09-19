module Aware::Webhooks::Incoming::Base
  extend ActiveSupport::Concern

  def update_customer(sub_arg)
    sub = Hashie::Mash.new(sub_arg)
    db_customer = StripeCustomer.find_or_create_by(customer_id: sub.id)
    db_customer.email  = sub.email
    db_customer.name  = sub.name
    db_customer.save
  end

  # def update_subscription_explicit(sub_arg)
  # end
  def update_subscription(sub_arg, db_customer_id = nil)

    if db_customer_id.present?
      sub = sub_arg
      db_customer = StripeCustomer.find(db_customer_id)
      db_subscription = StripeSubscription.find_or_create_by(stripe_customer_id: db_customer.id, subscription_id: sub.id)
    else
      sub = Hashie::Mash.new(sub_arg)
      db_customer = StripeCustomer.find_or_create_by(customer_id: sub.customer)
      db_subscription = StripeSubscription.find_or_create_by(stripe_customer_id: db_customer.id, subscription_id: sub.id)
    end

    # db_subscription = StripeSubscription.find_or_create_by(subscription_id: sub.id)
    db_subscription.discount  = sub.discount
    db_subscription.plan  = sub.plan
    db_subscription.quantity  = sub.quantity
    db_subscription.status  = sub.status
    db_subscription.trial_end  = unix_timestamp_to_date(sub.trial_end)
    db_subscription.trial_start  = unix_timestamp_to_date(sub.trial_start)
    db_subscription.price_after_discount  = subscription_value(sub)
    db_subscription.save
  end

  def unix_timestamp_to_date(timestamp)
    return if timestamp.blank?
    DateTime.strptime(timestamp.to_s, '%s')
  end

  def subscription_value(sub)

    total = 0
    percent_off = nil
    amount_off = nil

    if sub.discount
      percent_off = sub.discount.coupon.percent_off
      amount_off = sub.discount.coupon.amount_off
    end

    qty = sub.items.data[0].quantity
    amount = sub.plan.amount * qty
    final_price = amount

    if percent_off
      final_price = amount * ((100 - percent_off) / 100)
    end

    if amount_off
      final_price = amount - amount_off
      final_price = 0 if final_price < 0
    end

    total += final_price
    puts "total: #{total}"
    total
  end
end

