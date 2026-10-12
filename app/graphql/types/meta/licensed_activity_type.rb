# frozen_string_literal: true

module Types::Meta
  class LicensedActivityType < Types::Base::Object
    graphql_name 'LicensedActivityType'
    field :id, GraphQL::Types::ID, null: false
    timestamp_fields
  end
end
