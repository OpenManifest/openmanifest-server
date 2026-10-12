# frozen_string_literal: true

module Types::Meta
  class ActivityType < Types::Base::Object
    graphql_name 'ActivityType'
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    timestamp_fields
  end
end
