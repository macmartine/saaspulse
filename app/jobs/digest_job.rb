class DigestJob < ApplicationJob 

  include Webhooks::Incoming::Base

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  SEND_AT_HOUR = 7

  def perform(stripe_account_id, team_id)

    stripe_account = Integrations::StripeInstallation.find(stripe_account_id)
    team = Team.find(team_id)

    ingest_account(stripe_account.oauth_stripe_account.uid)

    stripe = StripeReport.new(stripe_account.id)
    # stripe.output_report
    stripe.run

    team.users.each do |team_member|
      puts team_member.email

      time_in_time_zone = Time.now.in_time_zone(team_member.time_zone)

      next if time_in_time_zone.hour != SEND_AT_HOUR

      # TODO: Only run on appropriate hour/timezone
      DigestMailer.digest(stripe, team.name, team_member.email).deliver_now
    end
  end

  private

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
        update_subscription(db_customer.id, sub)
      end

    end

  end


end
