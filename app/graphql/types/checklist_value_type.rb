# frozen_string_literal: true

module Types
  class ChecklistValueType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :checklist_item, Types::ChecklistItemType, null: false
    field :value, String, null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
