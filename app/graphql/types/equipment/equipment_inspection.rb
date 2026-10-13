# frozen_string_literal: true

module Types::Equipment
  class EquipmentInspection < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :definition, String, null: false
    field :is_ok, Boolean, null: false
    async_field :membership, Types::Users::Membership, null: false
    async_field :inspected_by, Types::Users::Membership, null: false
    async_field :form_template, Types::Equipment::EquipmentInspectionTemplate, null: false
    async_field :equipment, Types::Equipment::Equipment, null: true
    timestamp_fields
  end
end
