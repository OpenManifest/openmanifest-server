class NotifyJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    if notification = Notification.find(notification_id)
      notification.send!
    end
  end
end
