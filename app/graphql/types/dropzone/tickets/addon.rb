# frozen_string_literal: true

module Types::Dropzone::Tickets
  class Addon < Types::Base::Object
    graphql_name 'Extra'
    implements Types::Interfaces::SellableItem
    implements Types::Interfaces::Polymorphic
    def title
      object.name
    end
    field :cost, Float, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :dropzone, Types::DropzoneType, null: false
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :ticket_types, [Types::Dropzone::Ticket], null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
