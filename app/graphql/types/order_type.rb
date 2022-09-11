# frozen_string_literal: true

module Types
  class OrderType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :title, String, null: true
    field :receipts, [Types::ReceiptType], null: true
    field :dropzone, Types::DropzoneType, null: false
    field :item, Types::SellableItemType, null: true
    field :buyer, Types::WalletType, null: false
    field :seller, Types::WalletType, null: false
    field :state, Types::OrderStateType, null: false
    field :order_number, Int, null: false
    field :amount, Float, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
