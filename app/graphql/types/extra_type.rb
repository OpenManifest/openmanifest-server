# frozen_string_literal: true

module Types
  class ExtraType < Types::BaseObject
    implements Types::SellableItemType
    def title
      object.name
    end
    field :cost, Float, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :dropzone, Types::DropzoneType, null: false
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :ticket_types, [Types::TicketTypeType], null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
