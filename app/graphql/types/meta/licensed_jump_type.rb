# frozen_string_literal: true

module Types::Meta
  class LicensedJumpType < Types::Base::Object
    graphql_name 'LicensedJumpType'
    field :id, GraphQL::Types::ID, null: false
    timestamp_fields
  end
end
