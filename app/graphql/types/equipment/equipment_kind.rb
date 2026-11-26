# frozen_string_literal: true

module Types::Equipment
  class EquipmentKind < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :key, String, null: false
    field :name, String, null: false
    field :attribute_schema, GraphQL::Types::JSON, null: false,
                                                   description: "What an item of the kind records: attribute name => { type, values, required, default, min, max, unit, rentable }"
    field :service_interval_days, Int, null: true, description: "Days between services (a reserve repack); empty for a kind that is not serviced"
    field :inspection_valid_days, Int, null: true, description: "Days an inspection stays valid; empty: until the item is replaced"
    field :required_by, GraphQL::Types::JSON, null: false,
                                              description: "{ always } or { ticket_type_ids, activity_type_ids }: which slots need an item of the kind"
    field :position, Int, null: false
    async_field :inspection_form_template, Types::Equipment::EquipmentInspectionTemplate, null: true
    timestamp_fields
  end
end
