# frozen_string_literal: true

class Resolvers::Users::DropzoneUsers < Resolvers::Base
  type Types::Users::DropzoneUser.connection_type, null: true
  description "Search users at a dropzone"

  argument :dropzone, ::GraphQL::Types::ID, required: true,
                                            prepare: -> (value, ctx) { ::Dropzone.find_by(id: value) }
  argument :licensed, Boolean, required: false
  argument :permissions, [Types::Access::PermissionType], required: false
  argument :search, String, required: false

  def resolve(dropzone: nil, permissions: nil, search: nil, licensed: true, lookahead: nil)
    return nil unless dropzone
    query = apply_lookaheads(lookahead, dropzone.dropzone_users)
    query = query.includes(user_permissions: :permission) if permissions.present?

    query = query.where.not(license_id: nil) if licensed

    if permissions.present?
      query = query.where(
        user_role: UserRolePermission.includes(:permission, :user_role).where(
          permission: { name: permissions },
          user_role: { dropzone: dropzone }
        )
      ).or(
        query.where(
          user_permissions: {
            permissions: { name: permissions },
          }
        )
      )
    end
    query = query.search(search) if search.present?
    query
  end
end
