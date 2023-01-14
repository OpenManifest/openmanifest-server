# frozen_string_literal: true

module Types::Payments
  class Transaction < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :status, Types::Payments::TransactionStatus, null: false
    field :transaction_type, Types::Payments::TransactionType, null: false
    field :message, String, null: true
    field :amount, Float, null: false

    polymorphic_field :sender, Types::Interfaces::Wallet, null: false
    polymorphic_field :receiver, Types::Interfaces::Wallet, null: false
    async_field :dropzone_user, Types::Users::DropzoneUser, null: false
    async_field :receipt, Types::Payments::Receipt, null: false
    timestamp_fields
  end
end
