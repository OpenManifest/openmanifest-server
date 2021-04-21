# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :exit_weight, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
    field :rigs, [Types::RigType], null: true
    field :jump_types, [Types::JumpTypeType], null: true
    field :license, Types::LicenseType, null: true

    field :dropzone_users, [Types::DropzoneUserType], null: true
  end
end

