# frozen_string_literal: true

module Mutations
  class CreatePlane < Mutations::BaseMutation
    field :plane, Types::PlaneType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::PlaneInput, required: true

    def resolve(attributes:)
      model = Plane.new(attributes.to_h)

      model.save!

      {
        plane: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: invalid.record.errors.messages,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
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

    def authorized?(dropzone_id: nil)
      return context[:current_resource].can?(
        "createPlane",
        dropzone_id: dropzone_id
      ), {
        errors: [
          "You don't have permissions to create ticket addons"
          ]
        }
    end
  end
end
