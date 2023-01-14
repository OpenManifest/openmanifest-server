# frozen_string_literal: true

module Types::Equipment
  class RigInspection < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :dropzone_user, Types::Users::DropzoneUser, null: false
    field :inspected_by, Types::Users::DropzoneUser, null: false
    field :form_template, Types::Equipment::RigInspectionTemplate, null: false
    field :definition, String, null: false
    field :is_ok, Boolean, null: false
    field :rig, Types::Equipment::Rig, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
