# frozen_string_literal: true

module Mutations::Access
  class RevokePermission < Mutations::BaseMutation
    field :membership, Types::Users::Membership, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :permission, Types::Access::PermissionType,
             required: true,
             prepare: -> (value, ctx) { ::Permission.find_by(name: value) }

    argument :membership, ID, required: false,
                              prepare: -> (value, ctx) {
                                Membership.includes(:operator, :user, :user_permissions).find_by(id: value)
                              }

    def resolve(permission:, membership: nil)
      mutate(
        ::Access::RevokePermission,
        :membership,
        access_context: access_context_for(membership.operator),
        permission: permission,
        membership: membership
      )
    end

    def authorized?(membership: nil, permission: nil)
      current_dz_user = context[:current_resource].memberships.find_by(
        operator_id: membership.operator_id
      )

      # Users cannot revoke permissions they dont have,
      # except :actAsXXXX permissions (actAsGCA, actAsPilot)
      # To revoke any permissions, users must have :revokePermission

      if !current_dz_user.can?(:revokePermission)
        [
          false, {
            errors: [
              "You can't grant permissions for this operator",
            ],
          },
        ]
      elsif /^actAs.*/ !~ permission.name && !current_dz_user.can?(permission.name)
        [
          false, {
            errors: [
              "You can't grant permissions you don't have",
            ],
          },
        ]
      else
        true
      end
    end
  end
end
