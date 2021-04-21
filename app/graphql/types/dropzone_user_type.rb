# frozen_string_literal: true

module Types
  class DropzoneUserType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false

    field :user, Types::UserType, null: false
    field :role, Types::UserRoleType, null: true
    def role
      object.user_role
    end
    field :permissions, [Types::PermissionType], null: true
    def permissions
      Permission.includes(
        user_role: :dropzone_users
      ).where(
        user_roles: {
          dropzone_users: {
            user_id: object.user_id,
            dropzone_id: object.dropzone_id
            }
          }
        ).pluck(:name)
    end

    field :expires_at, Int, null: true
    field :credits, Int, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end
