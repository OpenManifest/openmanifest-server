# frozen_string_literal: true

module Types
  class UserQualificationType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :expires_at, Integer, null: true
    field :uid, String, null: true
  end
end
