# frozen_string_literal: true

module Types
  class PackType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
