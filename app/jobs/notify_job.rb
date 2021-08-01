# frozen_string_literal: true

class NotifyJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    if notification = Notification.find(notification_id)
      notification.send!
    end
  rescue
    # TODO: Handle these errors
    # Ignore if notification is removed before sending
  end
end
