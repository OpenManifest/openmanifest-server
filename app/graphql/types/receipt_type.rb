# frozen_string_literal: true

module Types
  class ReceiptType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :amount_cents, Integer, null: true
    field :order, Types::OrderType, null: false
    field :transactions, [Types::TransactionType], null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
