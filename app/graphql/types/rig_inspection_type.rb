# frozen_string_literal: true

module Types
  class RigInspectionType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :dropzone_user, Types::DropzoneUserType, null: false
    field :inspected_by, Types::DropzoneUserType, null: false
    field :form_template, Types::FormTemplateType, null: false
    field :definition, String, null: false
    field :is_ok, Boolean, null: false
    field :rig, Types::RigType, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
