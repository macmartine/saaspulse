class Webhooks::Incoming::StripeConnectWebhooksController < ApplicationController

  skip_before_action :verify_authenticity_token
  layout false

  def create
    # we have to validate stripe webhooks based on the text content of their payload,
    # so we have to do it before we convert it to json in the database.
    payload = request.body.read

    # this throws an exception if the signature is invalid.
    Stripe::Webhook.construct_event(
      payload,
      request.env["HTTP_STRIPE_SIGNATURE"],
      ENV["STRIPE_CONNECT_WEBHOOKS_ENDPOINT_SECRET"]
    )

    Aware::Webhooks::Incoming::StripeConnectWebhook.create(
      data: JSON.parse(payload),
      # we can mark this webhook as verified because we authenticated it earlier in this controller.
      verified_at: Time.zone.now
    ).process_async

    render json: {status: "OK"}, status: :created
  end
end

