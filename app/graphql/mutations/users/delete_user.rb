# frozen_string_literal: true

module Mutations::Users
  class DeleteUser < Mutations::BaseMutation
    field :dropzone_user, Types::DropzoneUserType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true,
      description: "The ID of the dropzone user to delete"

    def resolve(id:)
      model = DropzoneUser.find(id)

      model.discard

      {
        dropzone_user: model.reload,
        field_errors: nil,
        errors: nil
      }
    rescue Discard::RecordNotDiscarded
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: ["Failed to archive this user"]
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

    def authorized?(id: nil)
      dz_user = DropzoneUser.find(id)
      if context[:current_resource].id == dz_user.user.id
        true
      # We can't check for dropzones since User isn't directly
      # linked to any dropzone, but if this user only belongs to
      # one dropzone, and you have access to :updateUser at that dropzone,
      # then you can update the users profile. As soon as the user
      # joins other dropzones, you can no longer edit their profile
      elsif context[:current_resource].can?(:deleteUser, dropzone_id: dz_user.dropzone_id)
        true
      else
        return false, {
          errors: ["You cant delete this aircraft"]
        }
      end
    end
  end
end
