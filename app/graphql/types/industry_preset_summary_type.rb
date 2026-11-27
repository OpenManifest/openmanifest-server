# frozen_string_literal: true

class Types::IndustryPresetSummaryType < Types::Base::Object
  graphql_name "IndustryPresetSummary"
  description "What an industry template's presets create in a new operator, by name (the wizard's preview and review)"

  field :roles, [String], null: false, description: "The roles members can have"
  field :crew_roles, [String], null: false, description: "The crew roles of a load or vehicle"
  field :ticket_types, [String], null: false
  field :extras, [String], null: false
  field :destinations, [String], null: false
  field :equipment_kinds, [String], null: false
  field :activity_types, Int, null: false, description: "How many activity types are enabled"

  %w(roles crew_roles ticket_types extras destinations equipment_kinds activity_types).each do |key|
    define_method(key) { object.fetch(key) }
  end
end
