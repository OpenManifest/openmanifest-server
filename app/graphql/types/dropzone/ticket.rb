# frozen_string_literal: true

module Types::Dropzone
  class Ticket < Types::Base::Object
    graphql_name 'TicketType'
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::SellableItem
    lookahead do |query|
      query = query.includes(ticket_type_extras: :extra) if selects?(:extras)
      query
    end
    def title
      "#{object.name} ticket"
    end

    field :id, GraphQL::Types::ID, null: false
    field :currency, String, null: true
    field :cost_cents, Int, null: false
    def cost_cents
      object.cost_cents.to_i
    end
    field :cost, Float, null: false, deprecation_reason: "Use costCents, an integer number of cents"
    def cost
      object.cost_cents.to_i / 100.0
    end
    field :name, String, null: true
    field :altitude, Int, null: true
    field :allow_manifesting_self, Boolean, null: true
    field :is_tandem, Boolean, null: true
    field :extras, [Types::Dropzone::Tickets::Addon], null: false
    def extras
      dataloader.with(::Sources::AssociationLoader, [:extras]).load(object).extras
    end
    async_field :dropzone, Types::DropzoneType, null: true
    timestamp_fields
  end
end
