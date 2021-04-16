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
        field_errors: invalid.record.errors.messages,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
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
      return context[:current_resource].can?(
        "createLoad",
        dropzone_id: attributes[:dropzone_id]
      ), {
        errors: [
          "You don't have permissions to create ticket addons"
          ]
        }
    end
  end
end
