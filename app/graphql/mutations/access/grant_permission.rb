# frozen_string_literal: true

module Mutations::Access
  class GrantPermission < Mutations::BaseMutation
    field :dropzone_user, Types::DropzoneUserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :permission, Types::PermissionType,
             required: true,
             prepare: -> (value, ctx) { ::Permission.find_by(name: value) }

    argument :dropzone_user, ID, required: false,
                                 prepare: -> (value, ctx) { DropzoneUser.includes(:dropzone, :user, :user_permissions).find_by(id: value) }

    def resolve(permission:, dropzone_user: nil)
      mutate(
        ::Access::GrantPermission,
        :dropzone_user,
        access_context: access_context_for(dropzone_user.dropzone),
        permission: permission,
        dropzone_user: dropzone_user
      )
    end

    def authorized?(dropzone_user: nil, permission: nil)
      current_dz_user = context[:current_resource].dropzone_users.find_by(
        dropzone_id: dropzone_user.dropzone_id
      )

      # Users cannot grant permissions they dont have,
      # except :actAsXXXX permissions (actAsGCA, actAsPilot)
      # To grant any permissions, users must have :grantPermission

      if !current_dz_user.can?(:grantPermission)
        [
          false, {
            errors: [
              "You can't grant permissions for this dropzone",
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
