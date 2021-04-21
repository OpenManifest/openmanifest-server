# frozen_string_literal: true

module Types
  class ChecklistItemType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :value_type, Int, null: true
    field :is_required, Boolean, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false

    field :value, Types::ChecklistValueType, null: true
    def value
      # FIXME: FIGURE OUT HOW TO FIND VALUES FOR CHECKLIST ITEMS
    end
  end
end
