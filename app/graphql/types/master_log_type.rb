# frozen_string_literal: true

module Types
  class MasterLogType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :loads, [Types::LoadType], null: true
    field :dzso, [Types::DropzoneUserType], null: true

    field :dropzone, Types::DropzoneType, null: true
  end
end
