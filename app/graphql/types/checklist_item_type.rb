module Types
  class ChecklistItemType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :value_type, Int, null: true
    field :is_required, Boolean, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end