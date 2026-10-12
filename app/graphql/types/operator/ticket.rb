# frozen_string_literal: true

module Types::Operator
  class Ticket < Types::Base::Object
    graphql_name 'TicketType'
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::SellableItem
    def title
      "#{object.name} ticket"
    end

    field :id, GraphQL::Types::ID, null: false
    field :currency, String, null: true
    field :cost_cents, Int, null: false
    def cost_cents
      object.cost_cents.to_i
    end
    field :name, String, null: true
    async_field :default_destination, Types::Operator::Destination, null: true
    field :allow_manifesting_self, Boolean, null: true
    field :is_tandem, Boolean, null: true
    field :extras, [Types::Operator::Tickets::Addon], null: false
    def extras
      dataloader.with(::Sources::AssociationLoader, [:extras]).load(object).extras
    end
    async_field :operator, Types::OperatorType, null: true
    timestamp_fields
  end
end
