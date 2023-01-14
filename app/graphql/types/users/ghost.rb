# frozen_string_literal: true

module Types::Users
  class Ghost < Types::Base::Object
    field :email, String, null: true
    field :exit_weight, Integer, null: true
    field :id, GraphQL::Types::ID, null: false
    field :license, Types::Meta::License, null: true
    field :dropzone_users, [Types::Users::DropzoneUser], null: true
    field :phone, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :jump_types, [Types::Meta::JumpType], null: true
    field :updated_at, Integer, null: false
  end
end
