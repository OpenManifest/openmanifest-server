module Types
  class NotificationType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :message, String, null: true
    field :notification_type, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end