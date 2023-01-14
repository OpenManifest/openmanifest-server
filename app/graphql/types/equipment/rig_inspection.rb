# frozen_string_literal: true

module Types::Equipment
  class RigInspection < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :definition, String, null: false
    field :is_ok, Boolean, null: false
    async_field :dropzone_user, Types::Users::DropzoneUser, null: false
    async_field :inspected_by, Types::Users::DropzoneUser, null: false
    async_field :form_template, Types::Equipment::RigInspectionTemplate, null: false
    async_field :rig, Types::Equipment::Rig, null: true
    timestamp_fields
  end
end
