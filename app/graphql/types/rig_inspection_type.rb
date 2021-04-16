# frozen_string_literal: true

module Types
  class RigInspectionType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :dropzone_user, Types::DropzoneUser, null: false
    field :inspected_by, Types::User, null: false
    field :checklist, Types::Checklist, null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
