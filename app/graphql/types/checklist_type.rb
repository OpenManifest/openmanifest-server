# frozen_string_literal: true

module Types
  class ChecklistType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :checklist_items, [Types::ChecklistItemType], null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
