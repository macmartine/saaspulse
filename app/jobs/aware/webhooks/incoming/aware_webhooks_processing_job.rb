class Aware::Webhooks::Incoming::AwareWebhooksProcessingJob < ApplicationJob
  queue_as :default

  def perform(webhook)
    webhook.verify_and_process
  end
end
