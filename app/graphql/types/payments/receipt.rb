# frozen_string_literal: true

module Types::Payments
  class Receipt < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :amount_cents, Integer, null: true
    field :transactions, [Types::Payments::Transaction], null: false
    async_field :order, Types::Payments::Order, null: false
    timestamp_fields
  end
end
