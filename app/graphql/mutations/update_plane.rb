# frozen_string_literal: true

module Mutations
  class UpdatePlane < Mutations::BaseMutation
    field :plane, Types::PlaneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true
    argument :attributes, Types::Input::PlaneInput, required: true

    def resolve(attributes:, id:)
      model = Plane.find(id)

      model.update!(attributes.to_h)
      {
        plane: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        plane: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(id: nil, attribues: nil)
      if context[:current_resource].can?(
        "updatePlane",
        dropzone_id: Plane.find(id).dropzone_id
      )
        return true
      else
        return false, {
          errors: [
            "You don't have permissions to update this plane"
            ]
          }
      end
    end
  end
end
