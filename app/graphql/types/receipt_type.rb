# frozen_string_literal: true

module Types
  class ReceiptType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :amount_cents, Integer, null: true
    field :order, Types::OrderType, null: false
    field :transactions, [Types::TransactionType], null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
