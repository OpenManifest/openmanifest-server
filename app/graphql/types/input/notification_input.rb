module Types
  module Input
    class NotificationInput < Types::BaseInputObject
      argument :is_seen, Boolean, required: true
    end
  end
end