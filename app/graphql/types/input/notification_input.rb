# frozen_string_literal: true

module Types
  module Input
    class NotificationInput < Types::Base::Input
      argument :is_seen, Boolean, required: true
    end
  end
end
