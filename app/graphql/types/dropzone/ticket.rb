# frozen_string_literal: true

module Types::Dropzone
  class Ticket < Types::Base::Object
    graphql_name 'TicketType'
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::SellableItem
    def title
      "#{object.name} ticket"
    end

    field :id, GraphQL::Types::ID, null: false
    field :currency, String, null: true
    field :dropzone, Types::DropzoneType, null: true
    field :cost, Float, null: false
    field :name, String, null: true
    field :altitude, Int, null: true
    field :allow_manifesting_self, Boolean, null: true
    field :is_tandem, Boolean, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :extras, [Types::Dropzone::Tickets::Addon], null: false
  end
end
