# frozen_string_literal: true

module Mutations
  class CreateLoad < Mutations::BaseMutation
    field :load, Types::LoadType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::LoadInput, required: true

    def resolve(attributes:)
      model = Load.new(attributes.to_h)

      model.save!
      {
        load: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        load: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        load: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(attributes: nil)
      if context[:current_resource].can?(
        "createLoad",
        dropzone_id: Plane.find(attributes[:plane_id]).dropzone.id
      )
        true
      else
        return false, {
          errors: [
            "You don't have permissions to create loads"
            ]
          }
      end
    end
  end
end
