class AddStripeConnectWebhooks < ActiveRecord::Migration[7.0]
  def change

    create_table "stripe_connect_webhooks", force: :cascade do |t|
      t.jsonb "data"
      t.datetime "processed_at", precision: nil
      t.datetime "verified_at", precision: nil
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

  end
end
