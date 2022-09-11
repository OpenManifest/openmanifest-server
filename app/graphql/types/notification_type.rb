# frozen_string_literal: true

module Types
  class NotificationType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :message, String, null: true
    field :is_seen, Boolean, null: false
    field :notification_type, Types::NotificationTypeType, null: true
    field :resource, Types::AnyResourceType, null: true

    field :received_by, Types::DropzoneUserType, null: false
    field :sent_by, Types::DropzoneUserType, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
