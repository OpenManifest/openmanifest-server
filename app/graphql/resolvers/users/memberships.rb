# frozen_string_literal: true

class Resolvers::Users::Memberships < Resolvers::Base
  type Types::Users::Membership.connection_type, null: true
  description "Search users at an operator"

  argument :operator, ::GraphQL::Types::ID, required: true,
                                            prepare: -> (value, ctx) { ::Operator.find_by(id: value) }
  argument :licensed, Boolean, required: false
  argument :permissions, [Types::Access::PermissionType], required: false
  argument :search, String, required: false

  def resolve(operator: nil, permissions: nil, search: nil, licensed: true)
    return nil unless operator

    authorize_operator!(operator, :readUser)
    query = operator.memberships
    query = query.includes(user_permissions: :permission) if permissions.present?

    query = query.where.not(license_id: nil) if licensed

    if permissions.present?
      # Roles of this operator that grant any of the permissions (BUG-093: this used to compare role ids with
      # UserRolePermission ids)
      roles = UserRole.where(operator: operator, id: UserRolePermission.joins(:permission).where(permissions: { name: permissions }).select(:user_role_id))
      query = query.where(user_role_id: roles.select(:id)).or(
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
