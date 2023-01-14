# frozen_string_literal: true

module Types::Dropzone::Tickets
  class Addon < Types::Base::Object
    graphql_name 'Extra'
    implements Types::Interfaces::SellableItem
    implements Types::Interfaces::Polymorphic
    lookahead do |query|
      query = query.includes(ticket_type_extras: :ticket_type) if selects?(:ticket_types)
      query
    end
    def title
      object.name
    end
    field :cost, Float, null: false
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :ticket_types, [Types::Dropzone::Ticket], null: false
    async_field :dropzone, Types::DropzoneType, null: false
    timestamp_fields
  end
end
