module Types
  class GhostType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :email, String, null: true
    field :phone, String, null: true
    field :exit_weight, Integer, null: true
    field :license, Types::LicenseType, null: true
    field :dropzone_users, [Types::DropzoneUserType], null: true
    field :jump_types, [Types::JumpTypeType], null: true
    field :license, Types::LicenseType, null: true
    field :created_at, Integer, null: false
    field :updated_at,  Integer, null: false
  end
end