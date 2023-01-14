# frozen_string_literal: true

module Types::Meta
  class JumpType < Types::Base::Object
    graphql_name 'JumpType'
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    timestamp_fields
  end
end
