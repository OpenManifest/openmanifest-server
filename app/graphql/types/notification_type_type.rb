# frozen_string_literal: true

class Types::NotificationTypeType < Types::BaseEnum
  Notification.notification_types.each do |name,|
    value name.to_s, name.to_s
  end
end
