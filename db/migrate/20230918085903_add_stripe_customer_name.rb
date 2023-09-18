class AddStripeCustomerName < ActiveRecord::Migration[7.0]
  def change
    add_column :stripe_customers, :name, :string
  end
end
