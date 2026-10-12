# frozen_string_literal: true

class Types::IndustryTemplateType < Types::Base::Object
  graphql_name "IndustryTemplate"
  description "What an operator of an industry starts with: modules, terms, and the presets copied into it"

  field :slug, Types::IndustryEnum, null: false
  field :name, String, null: false
  field :description, String, null: false
  field :icon, String, null: false, description: "A MaterialCommunityIcons glyph"
  field :base, String, null: true, description: "The family (the abstract base the template extends): _aviation, _water, _ground"
  field :modules, [String], null: false
  field :preset_summary, GraphQL::Types::JSON, null: false, description: "How many roles, ticket types, extras and activity types the presets create"

  def base
    object.extends
  end

  def modules
    object.modules.keys
  end
end
