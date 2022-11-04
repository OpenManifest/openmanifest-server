# frozen_string_literal: true

class Resolvers::Users::DropzoneUsers < Resolvers::Base
  type Types::DropzoneUserType.connection_type, null: true
  description "Search users at a dropzone"

  argument :permissions, [Types::PermissionType], required: false
  argument :search, String, required: false
  argument :licensed, Boolean, required: false
  argument :dropzone, ::GraphQL::Types::ID, required: true,
           prepare: -> (value, ctx) { ::Dropzone.find_by(id: value) }

  def resolve(dropzone: nil, permissions: nil, search: nil, licensed: true, lookahead: nil)
    lookahead = lookahead.selection(:edges).selection(:node)
    return nil unless dropzone
    query = dropzone.dropzone_users
    query = query.includes(:user_role)  if lookahead.selects?(:role)
    query = query.includes(:dropzone)   if lookahead.selects?(:dropzone)
    query = query.includes(:jump_types) if lookahead.selects?(:jump_type)
    query = query.includes(:slots)      if lookahead.selects?(:slots)
    query = query.includes(:user)       if lookahead.selects?(:user)
    query = query.includes(:license)    if lookahead.selects?(:license)
    query = query.includes(user_permissions: :permission) unless permissions.blank?

    query = query.where.not(license_id: nil) if licensed

    unless permissions.blank?
      query = query.where(
        user_role: UserRolePermission.includes(:permission, :user_role).where(
          permission: { name: permissions },
          user_role: { dropzone: dropzone }
        )
      ).or(
        query.where(
          user_permissions: {
            permissions: { name: permissions }
          }
        )
      )
    end
    query = query.search(search) unless search.blank?
    query
  end
end
