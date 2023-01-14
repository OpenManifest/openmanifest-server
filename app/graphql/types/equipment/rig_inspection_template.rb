# frozen_string_literal: true

module Types::Equipment
  class RigInspectionTemplate < Types::Base::Object
    graphql_name 'FormTemplate'
    field :definition, String, null: true
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    timestamp_fields
  end
end
