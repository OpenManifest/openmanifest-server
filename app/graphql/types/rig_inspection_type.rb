# frozen_string_literal: true

module Types
  class RigInspectionType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :dropzone_user, Types::DropzoneUserType, null: false
    field :inspected_by, Types::UserType, null: false
    field :checklist, Types::ChecklistType, null: false
    field :checklist_values, [Types::ChecklistValueType], null: false
    field :rig, Types::RigType, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
