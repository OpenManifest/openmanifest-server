# frozen_string_literal: true

module Mutations::Users
  class UpdateDropzoneUser < Mutations::BaseMutation
    field :dropzone_user, Types::Users::DropzoneUser, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :attributes, Types::Input::DropzoneUserInput, required: true
    argument :dropzone_user, ID, required: false,
                                 prepare: -> (value, ctx) { DropzoneUser.find_by(id: value) }

    # What staff can change on a membership; the member's profile (name, email, ...) is updateUser's
    UPDATABLE = %i(expires_at credits credits_cents user_role_id).freeze

    def resolve(dropzone_user:, attributes: nil)
      attrs = attributes.to_h.slice(*UPDATABLE)
      attrs[:expires_at] = Time.zone.at(attrs[:expires_at]) if attrs[:expires_at]
      dropzone_user.assign_attributes(attrs)
      dropzone_user.save!

      {
        dropzone_user: dropzone_user,
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

    # Staff with updateUser at the member's dropzone. A role is changed only to a role of that dropzone below the
    # caller's own, for a member whose own role is below the caller's too (a manager cannot demote the owner).
    def authorized?(dropzone_user: nil, attributes: nil)
      return refuse("Member not found") unless dropzone_user

      acting = DropzoneUser.membership(dropzone_user.dropzone, context[:current_resource])
      return refuse("You don't have permission to update this") unless acting&.can?(:updateUser)

      role_id = attributes&.[](:user_role_id)
      return true if role_id.nil? || role_id == dropzone_user.user_role_id

      return refuse("That role does not belong to this dropzone") unless dropzone_user.dropzone.user_roles.exists?(id: role_id)

      assignable = acting.can?(:grantPermission) && role_id < acting.user_role_id && dropzone_user.user_role_id < acting.user_role_id
      assignable ? true : refuse("You don't have permissions to assign this role")
    end

    private

    def refuse(message)
      [false, { dropzone_user: nil, field_errors: nil, errors: [message] }]
    end
  end
end
