class StripeReport

  def initialize(stripe_account_id)
    # @timezone = timezone
    # @timezone = Team.first.time_zone
    # @stripe_account_id = stripe_account_id
    @team = Integrations::StripeInstallation.find(stripe_account_id)
    @stripe_account_id = @team.oauth_stripe_account.uid
  end

  def run
    @total_active_customers = total_active_customers
    @new_active_customers = new_active_customers
    @total_in_trial = total_in_trial
    @trials_converting_today = obj_print trials_converting_today
    @trials_converting_after_today = trials_converting_after_today
    # @trials_converting_next_7_days = trials_converting_next_7_days
    # @trials_converting_after_7_days = obj_print trials_converting_after_7_days
    @conversions_last_24_hrs = obj_print conversions_last_24_hrs
    @canceled_recently = canceled_recently 
    @past_due = past_due  
    @paused = paused
    @unpaid = unpaid
    @incomplete = incomplete
    @mrr = mrr
    @new_mrr = new_mrr
  end

  def output_users
    str = ""
    active_customers.each do |a|
      str += "#{a.stripe_customer.email}, #{a.status}, #{a.stripe_customer.customer_id}, #{a.subscription_id}, #{a.price_after_discount/ 100}\r\n"
    end

    File.write("active_subscribers.csv", str)
  end

  def output_report
    puts "Total active customers: #{total_active_customers}"
    puts ""
    puts "Total trialing: #{total_in_trial}"
    puts ""
    puts "Trials converting today : #{obj_print trials_converting_today}"
    puts ""
    # puts "Trials converting next 7 days : #{trials_converting_next_7_days}"
    puts ""
    # puts "Trials converting after 7 days : #{obj_print trials_converting_after_7_days}"
    # puts ""
    puts "Conversions last 24 hours: #{obj_print conversions_last_24_hrs}"
    puts ""
    puts "Canceled recently: #{canceled_recently}"
    puts ""
    puts "Past due: #{past_due}"
    puts ""
    puts "Paused: #{paused}"
    puts ""
    puts "Unpaid: #{unpaid}"
    puts ""
    puts "Incomplete: #{incomplete}"
    puts ""
    puts "MRR: #{mrr}"
  end

  def obj_print(obj)
    puts ""
    puts "Data: #{obj[:data]}"
  end

  def timestamps(start_days_from_now, end_days_from_now)

    time_in_timezone = Time.now.in_time_zone(@timezone)
    today = Time.now

    start = today.advance(days: start_days_from_now)
    start = start.change(hour: 2, min: 0, sec: 0)

    end_time = today.advance(days: end_days_from_now)
    end_time = end_time.change(hour: 23, min: 59, sec: 59)

    [start, end_time]
  end

  def query(q, *args)
    stripe_subscription_query.where(q, *args)
  end

  def stripe_subscription_query
    StripeSubscription.includes(:stripe_customer).where(stripe_customers: { account_id: @stripe_account_id })
  end

  def generate_data(data)
    # r = data
    r = data.sort_by { |x| x.days_til_conversion }
    # ser = ActiveModel::Serializer::CollectionSerializer.new(r, serializer: StripeSubscriptionSerializer)
    # { data: ser.as_json, totalValue: r.sum(&:price_after_discount) }
    # binding.pry
    { data: r, totalValue: r.sum(&:price_after_discount) }
  end

  def active_customers
    # Note: Sometimes a subscription is removed so we don't update status.
    # So we set trial_end date to future so we don't get old subs
    query( "(status = 'active' OR status = 'past_due') AND cancel_at IS NULL AND price_after_discount > 0")
  end

  def total_active_customers
    # Note: Sometimes a subscription is removed so we don't update status.
    # So we set trial_end date to future so we don't get old subs
    active_customers.length
  end

  def new_active_customers
    # Note: Sometimes a subscription is removed so we don't update status.
    # So we set trial_end date to future so we don't get old subs
    query( "(status = 'active' OR status = 'past_due') AND cancel_at IS NULL AND price_after_discount > 0 AND trial_end > ?", t_24_hours_ago).length
  end

  def total_in_trial
    ts = timestamps(0, 0)
    query( "status = 'trialing' AND cancel_at IS NULL AND trial_end >= ?", ts[0] ).length
  end

  def t_24_hours_ago
    Time.now.utc - 24.hours
  end

  def next_24_hours
    Time.now.utc + 24.hours
  end

  def new_in_trial
    query( "status = 'trialing' AND cancel_at IS NULL AND trial_start > ?", t_24_hours_ago ).length
  end

  def trials_converting_today
    # ts = timestamps(0, 1)
    # i = query( "status = 'trialing' AND cancel_at IS NULL AND trial_end >= ? AND trial_end <= ?", ts[0], ts[1])
    i = query( "status = 'trialing' AND cancel_at IS NULL AND trial_end <= ?", next_24_hours )
    generate_data(i)
  end

  def trials_converting_after_today
    # ts = timestamps(1, 1)
    # i = query( " status = 'trialing' AND cancel_at IS NULL AND trial_end >= ?", ts[0])
    i = query( " status = 'trialing' AND cancel_at IS NULL AND trial_end > ?", next_24_hours)
    generate_data(i)
  end

  # def trials_converting_next_7_days
  #   ts = timestamps(0, 6)
  #   i = query( " status = 'trialing' AND cancel_at IS NULL AND trial_end >= ? AND trial_end <= ?", ts[0], ts[1])
  #   generate_data(i)
  # end
  #
  # def trials_converting_after_7_days
  #   ts = timestamps(7, 10000)
  #   i = query( " status = 'trialing' AND cancel_at IS NULL AND trial_end >= ? AND trial_end <= ?", ts[0], ts[1])
  #   generate_data(i)
  # end

  def conversions_last_24_hrs
    ts = timestamps(-1, -1)
    i = query( " status = 'trialing' AND cancel_at IS NULL AND trial_end >= ? AND trial_end <= ?", ts[0], ts[1])
    generate_data(i)
  end

  def canceled_recently
    # i = query( " status = 'trialing' AND cancel_at IS NOT NULL AND cancel_at > ?", Time.now.utc)
    i = query( " status = 'active' AND cancel_at IS NOT NULL AND cancel_at > ?", Time.now.utc)
    generate_data(i)
  end

  def mrr
    a = query( " (status = 'active' OR status = 'past_due') AND cancel_at IS NULL AND price_after_discount > 0")
    a.sum { |i| i.price_after_discount } / 100.0
  end

  def new_mrr
    a = query( " (status = 'active' OR status = 'past_due') AND cancel_at IS NULL AND price_after_discount > 0 AND trial_end > ?", t_24_hours_ago)
    a.sum { |i| i.price_after_discount } / 100.0
  end

  # Bad payments
  def past_due
    i = stripe_subscription_query.includes(:stripe_customer).where( "status = 'past_due'")
  
    generate_data(i)
  end

  def unpaid
    i = stripe_subscription_query.includes(:stripe_customer).where( "status = 'unpaid'")
    generate_data(i)
  end

  def incomplete
    i = stripe_subscription_query.includes(:stripe_customer).where( "status = 'incomplete'")
    generate_data(i)
  end

  def paused
    i = stripe_subscription_query.includes(:stripe_customer).where( "status = 'paused'")
    generate_data(i)
  end

end


