# frozen_string_literal: true

module Types::Payments
  class Order < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :title, String, null: true
    field :receipts, [Types::Payments::Receipt], null: true
    field :dropzone, Types::DropzoneType, null: false
    field :item, Types::Interfaces::SellableItem, null: true
    field :buyer, Types::Interfaces::Wallet, null: false
    field :seller, Types::Interfaces::Wallet, null: false
    field :state, Types::Payments::OrderState, null: false
    field :order_number, Int, null: false
    field :amount, Float, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
