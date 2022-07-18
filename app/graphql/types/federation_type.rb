# frozen_string_literal: true

module Types
  class FederationType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :slug, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :licenses, [Types::LicenseType], null: true
  end
end
