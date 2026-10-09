# frozen_string_literal: true

module Mutations::Users
  class DeleteUser < Mutations::BaseMutation
    field :dropzone_user, Types::Users::DropzoneUser, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :id, Int, required: true,
                       description: "The ID of the dropzone user to delete"

    def resolve(id:)
      model = DropzoneUser.find(id)

      model.discard!

      {
        dropzone_user: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue Discard::RecordNotDiscarded
      {
        dropzone_user: nil,
        field_errors: nil,
        errors: ["Failed to archive this user"],
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

    def authorized?(id: nil)
      dz_user = DropzoneUser.find_by(id: id)
      return [false, { dropzone_user: nil, field_errors: nil, errors: ["Member not found"] }] unless dz_user

      # Members can remove themselves, staff need deleteUser at the member's dropzone
      if context[:current_resource].id == dz_user.user_id || context[:current_resource].can?(:deleteUser, dropzone_id: dz_user.dropzone_id)
        true
      else
        [false, { dropzone_user: nil, field_errors: nil, errors: ["You can't remove this member"] }]
      end
    end
  end
end
