# frozen_string_literal: true

module Mutations::Setup::Aircrafts
  class UpdatePlane < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :plane, Types::Dropzone::Aircraft, null: true

    argument :attributes, Types::Input::PlaneInput, required: true
    argument :id, Int, required: true

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
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        plane: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updatePlane",
        dropzone_id: Plane.find(id).dropzone_id
      )
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to update this plane",
            ],
          },
        ]
      end
    end
  end
end
