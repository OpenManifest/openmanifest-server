# frozen_string_literal: true

module Types::Payments
  class Order < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :title, String, null: true
    field :receipts, [Types::Payments::Receipt], null: true
    field :state, Types::Payments::OrderState, null: false
    field :order_number, Int, null: false
    field :amount_cents, Int, null: false
    def amount_cents
      object.amount_cents.to_i
    end
    field :amount, Float, null: false, deprecation_reason: "Use amountCents, an integer number of cents"
    def amount
      object.amount_cents.to_i / 100.0
    end
    async_field :dropzone, Types::DropzoneType, null: false
    polymorphic_field :item, Types::Interfaces::SellableItem, null: true
    polymorphic_field :buyer, Types::Interfaces::Wallet, null: true
    polymorphic_field :seller, Types::Interfaces::Wallet, null: true
    timestamp_fields
  end
end
