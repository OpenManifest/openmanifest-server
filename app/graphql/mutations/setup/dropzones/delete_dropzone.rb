# frozen_string_literal: true

module Mutations::Setup::Dropzones
  class DeleteDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Dropzone.kept.find(id)

      model.discard

      {
        dropzone: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue Discard::RecordNotDiscarded
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: ["Failed to archive this aircraft"],
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        dropzone: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        dropzone: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      dz_user = Dropzone.find(id).dropzone_users.find_by(user_id: context[:current_user])
      if dz_user.can? :deleteDropzone
        true
      else
        [
          false, {
            errors: ["You cant delete this dropzone"],
          },
        ]
      end
    end
  end
end
