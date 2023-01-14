# frozen_string_literal: true

module Types::System
  class Notification < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    field :message, String, null: true
    field :is_seen, Boolean, null: false
    field :notification_type, Types::System::NotificationType, null: true
    field :resource, Types::Interfaces::Polymorphic, null: true

    field :received_by, Types::Users::DropzoneUser, null: false
    field :sent_by, Types::Users::DropzoneUser, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
