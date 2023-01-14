# frozen_string_literal: true

module Types::Payments
  class Transaction < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :receipt, Types::Payments::Receipt, null: false
    field :status, Types::Payments::TransactionStatus, null: false
    field :transaction_type, Types::Payments::TransactionType, null: false
    field :sender, Types::Interfaces::Wallet, null: false
    field :receiver, Types::Interfaces::Wallet, null: false
    field :message, String, null: true
    field :amount, Float, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :dropzone_user, Types::Users::DropzoneUser, null: false
  end
end
