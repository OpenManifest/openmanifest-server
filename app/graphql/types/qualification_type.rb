# frozen_string_literal: true

module Types
  class QualificationType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
  end
end
