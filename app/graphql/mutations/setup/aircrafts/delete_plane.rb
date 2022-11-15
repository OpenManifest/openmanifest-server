# frozen_string_literal: true

module Mutations::Setup::Aircrafts
  class DeletePlane < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true
    field :plane, Types::PlaneType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Plane.find(id)

      model.discard!

      {
        plane: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue Discard::RecordNotDiscarded
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: ["Failed to archive this aircraft"],
      }

    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        plane: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        plane: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      plane = Plane.find(id)

      if context[:current_resource].can?(
        :deletePlane,
        dropzone_id: plane.dropzone_id
      )
        true
      else
        [
          false, {
            errors: ["You cant delete this aircraft"],
          },
        ]
      end
    end
  end
end
