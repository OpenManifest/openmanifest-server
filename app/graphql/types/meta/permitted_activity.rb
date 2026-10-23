# frozen_string_literal: true

module Types::Meta
  class PermittedActivity < Types::Base::Object
    graphql_name 'PermittedActivity'
    field :id, GraphQL::Types::ID, null: false
    timestamp_fields
  end
end
