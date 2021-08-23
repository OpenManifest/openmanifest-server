# frozen_string_literal: true

module Types
  class TransactionType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :receipt, Types::ReceiptType, null: false
    field :status, Types::TransactionStatusType, null: false
    field :transaction_type, Types::TransactionTypeType, null: false
    field :sender, Types::WalletType, null: false
    field :receiver, Types::WalletType, null: false
    field :message, String, null: true
    field :amount, Float, null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false

    field :dropzone_user, Types::DropzoneUserType, null: false
  end
end
