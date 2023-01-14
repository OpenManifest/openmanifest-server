# frozen_string_literal: true

module Types::Payments
  class Receipt < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :amount_cents, Integer, null: true
    field :order, Types::Payments::Order, null: false
    field :transactions, [Types::Payments::Transaction], null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
