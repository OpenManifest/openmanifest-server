# frozen_string_literal: true

module Types::Operator::Tickets
  class Addon < Types::Base::Object
    graphql_name 'Extra'
    implements Types::Interfaces::SellableItem
    implements Types::Interfaces::Polymorphic
    def title
      object.name
    end
    field :cost_cents, Int, null: false
    def cost_cents
      object.cost_cents.to_i
    end
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    async_field :required_qualification, Types::Meta::Qualification, null: true
    async_field :ticket_types, [Types::Operator::Ticket], null: false
    async_field :operator, Types::OperatorType, null: false
    timestamp_fields
  end
end
