# frozen_string_literal: true

module Types::Payments
  class Transaction < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :status, Types::Payments::TransactionStatus, null: false
    field :transaction_type, Types::Payments::TransactionType, null: false
    field :message, String, null: true
    field :amount_cents, Int, null: false
    def amount_cents
      object.amount_cents.to_i
    end

    polymorphic_field :sender, Types::Interfaces::Wallet, null: true
    polymorphic_field :receiver, Types::Interfaces::Wallet, null: true
    async_field :membership, Types::Users::Membership, null: false
    async_field :receipt, Types::Payments::Receipt, null: false
    timestamp_fields
  end
end
