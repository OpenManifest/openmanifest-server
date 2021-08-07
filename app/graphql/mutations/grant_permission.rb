# frozen_string_literal: true

module Mutations
  class GrantPermission < Mutations::BaseMutation
    field :dropzone_user, Types::DropzoneUserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :permission, Types::PermissionType, required: true
    argument :id, Int, required: false

    def resolve(permission:, id: nil)
      model = DropzoneUser.find(id)

      model.grant! permission
      model.user_permissions.reload

      Notification.create(
        received_by: model,
        message: "Permission granted: #{permission}",
        notification_type: :permission_granted,
        resource: model,
        sent_by: model.dropzone.dropzone_users.find_by(id: context[:current_resource].id)
      )

      {
        dropzone_user: model.reload,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone_user: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        dropzone_user: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone_user: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, permission: nil)
      dz_user = DropzoneUser.find(id)
      current_dz_user = context[:current_resource].dropzone_users.find_by(
        dropzone_id: dz_user.dropzone_id
      )

      # Users cannot grant permissions they dont have,
      # except :actAsXXXX permissions (actAsGCA, actAsPilot)
      # To grant any permissions, users must have :grantPermission

      if !current_dz_user.can?(:grantPermission)
        return false, {
          errors: [
            "You can't grant permissions for this dropzone"
          ]
        }
      elsif /^actAs.*/ !~ permission && !current_dz_user.all_permissions.includes?(permission)
        return false, {
          errors: [
            "You can't grant permissions you don't have"
          ]
        }
      else
        true
      end
    end
  end
end
