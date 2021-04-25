# frozen_string_literal: true

module Types
  class ChecklistItemType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :description, String, null: true
    field :value_type, String, null: true
    field :is_required, Boolean, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
