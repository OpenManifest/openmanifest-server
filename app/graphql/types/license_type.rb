# frozen_string_literal: true

module Types
  class LicenseType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :federation, Types::FederationType, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
