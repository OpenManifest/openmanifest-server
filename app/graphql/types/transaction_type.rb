# frozen_string_literal: true

module Types
  class TransactionType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :status, String, null: true
    field :message, String, null: true
    field :amount, Float, null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false

    field :dropzone_user, Types::DropzoneUserType, null: false
  end
end
