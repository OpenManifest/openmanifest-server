# frozen_string_literal: true

module Types::Equipment
  class RigInspectionTemplate < Types::Base::Object
    graphql_name 'FormTemplate'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :definition, String, null: true
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
