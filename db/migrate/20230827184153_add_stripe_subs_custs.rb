class AddStripeSubsCusts < ActiveRecord::Migration[7.0]

  def change
    create_table :stripe_customers do |t|
      t.string :account_id
      t.string :customer_id
      t.string :email
      t.jsonb :subscriptions

      t.timestamps
    end

    create_table :stripe_subscriptions do |t|
      t.integer :stripe_customer_id
      t.string :subscription_id
      t.timestamp :cancel_at
      t.timestamp :canceled_at
      t.jsonb :cancellation_details
      t.timestamp :created
      t.jsonb :discount
      t.timestamp :ended_at
      t.jsonb :plan
      t.integer :quantity
      t.timestamp :start_date
      t.string :status
      t.timestamp :trial_end
      t.timestamp :trial_start
      t.integer :price_after_discount

      t.timestamps
    end

  end
end
