# frozen_string_literal: true

class NotifyJob < ApplicationJob
  queue_as :default

  # Network trouble talking to the push service: try again later (about 3 s, 18 s, 83 s, ...)
  retry_on Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, HTTParty::Error,
           wait: :polynomially_longer, attempts: 5

  # The notification was removed before it was sent
  discard_on ActiveRecord::RecordNotFound

  def perform(notification_id)
    Notification.find(notification_id).send!
  end
end
