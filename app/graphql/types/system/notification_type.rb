# frozen_string_literal: true

class Types::System::NotificationType < Types::Base::Enum
  graphql_name 'NotificationType'
  Notification.notification_types.each do |name,|
    value name.to_s, name.to_s
  end
end
