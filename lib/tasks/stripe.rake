
namespace :stripe do

  task report: :environment do

    # TODO: Get only active accounts
    #

    Team.all.each do |team|
      puts "Team"

      all_stripe_accounts = team.integrations_stripe_installations
      all_stripe_accounts.each do |stripe_account|
        stripe = StripeReport.new(stripe_account.id)
        stripe.output_report

        team.users.each do |team_member|
          puts team_member.email

          # TODO: Only run on appropriate hour/timezone
          DigestMailer.digest(stripe, team_member.email).deliver_now
        end
      end
    end

  end

  task ingest: :environment do

    # TODO: Get only active accounts

    Team.all.each do |team|
      all_stripe_accounts = team.integrations_stripe_installations
      all_stripe_accounts.each do |stripe_account|
        stripe = stripe_account.oauth_stripe_account
        ingest_account(stripe.uid)
      end
    end

  end

end

def ingest_account(stripe_account_id)

  account_param = { stripe_account: stripe_account_id }

  customers = Stripe::Customer.list({}, account_param)

  return if customers.blank?

  customers.auto_paging_each do |customer|

    puts customer.id

    db_customer = StripeCustomer.find_or_create_by(account_id: stripe_account_id, customer_id: customer.id)
    db_customer.email  = customer.email
    db_customer.save

    subscriptions = Stripe::Subscription.list({
      customer: customer.id,
      status: 'all'
    }, account_param)

    puts "Subs"

    subscriptions.each do |sub|

      puts sub.id

      db_subscription = StripeSubscription.find_or_create_by(stripe_customer_id: db_customer.id, subscription_id: sub.id)
      db_subscription.discount  = sub.discount
      db_subscription.plan  = sub.plan
      db_subscription.quantity  = sub.quantity
      db_subscription.status  = sub.status
      db_subscription.trial_end  = unix_timestamp_to_date(sub.trial_end)
      db_subscription.trial_start  = unix_timestamp_to_date(sub.trial_start)
      db_subscription.price_after_discount  = subscription_value(sub)
      db_subscription.save

    end

  end

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

