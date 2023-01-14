# frozen_string_literal: true

module Types::System
  class Notification < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    field :message, String, null: true
    field :is_seen, Boolean, null: false
    field :notification_type, Types::System::NotificationType, null: true

    polymorphic_field :resource
    async_field :received_by, Types::Users::DropzoneUser, null: false
    async_field :sent_by, Types::Users::DropzoneUser, null: true
    timestamp_fields
  end
end
