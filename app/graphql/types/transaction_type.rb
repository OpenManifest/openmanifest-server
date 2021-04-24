module Types
  class TransactionType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :status, Int, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end