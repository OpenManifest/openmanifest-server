module Types
  class NotificationType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :message, String, null: true
    field :is_seen, Boolean, null: false
    field :notification_type, String, null: true
    field :resource, Types::AnyResourceType, null: true

    field :received_by, Types::DropzoneUserType, null: false
    field :sent_by, Types::DropzoneUserType, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end