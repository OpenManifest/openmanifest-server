# frozen_string_literal: true

module Types::Meta
  class LicensedJumpType < Types::Base::Object
    graphql_name 'LicensedJumpType'
    field :id, GraphQL::Types::ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
