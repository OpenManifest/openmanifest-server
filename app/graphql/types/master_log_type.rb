# frozen_string_literal: true

module Types
  class MasterLogType < Types::Base::Object
    field :id, GraphQL::Types::ID, null: false
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :loads, [Types::Manifest::Load], null: true
    field :dzso, [Types::Users::DropzoneUser], null: true

    field :dropzone, Types::DropzoneType, null: true
  end
end
