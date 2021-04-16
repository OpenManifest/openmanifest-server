# frozen_string_literal: true

module Mutations
  class UpdateDropzone < Mutations::BaseMutation
    field :dropzone, Types::DropzoneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::DropzoneInput, required: true

    def resolve(attributes:, id:)
      model = Dropzone.find(id)

      model.update!(attributes.to_h)
      {
        dropzone: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: invalid.record.errors.messages,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        ticket_type: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        ticket_type: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil)
      return context[:current_resource].can?(
        "createTicketType",
        dropzone_id: id
      ), {
        errors: [
          "You don't have permissions to create ticket types"
          ]
        }
    end
  end
end
