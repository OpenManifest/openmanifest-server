# frozen_string_literal: true

module Mutations::Users
  class UpdateDropzoneUser < Mutations::BaseMutation
    field :dropzone_user, Types::DropzoneUserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::DropzoneUserInput, required: true
    argument :dropzone_user, ID, required: false,
             prepare: -> (value, ctx) { DropzoneUser.find_by(id: value) }

    def resolve(attributes:, id: nil)
      model = DropzoneUser.find(id)

      attrs = attributes.to_h
      if attrs[:expires_at]
        attrs[:expires_at] = Time.at(attributes[:expires_at])
      end
      model.assign_attributes(attrs)
      model.save!

      {
        dropzone_user: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone_user: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        dropzone_user: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone_user: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      dropzone_user = DropzoneUser.find(id)
      current_dz_user = context[:current_resource].dropzone_users.find_by(
        dropzone: dropzone_user.dropzone
      )

      allowed_to_update_others = current_dz_user.can?(:updateUser)
      is_role_changed = attributes[:user_role_id] && attributes[:user_role_id] != dropzone_user.user_role_id
      is_allowed_to_change_role = current_dz_user.can?(:grantPermission) && attributes[:user_role_id] < current_dz_user.user_role_id

      # Check if the user is trying to change the UserRole:
      if allowed_to_update_others && is_role_changed && !is_allowed_to_change_role
        [
          false, {
            errors: [
              "You don't have permissions to assign this role",
            ],
          },
        ]
      elsif !allowed_to_update_others
        [
          false, {
            errors: [
              "You don't have permission to update this",
            ],
          },
        ]
      else
        true
      end
    end
  end
end
