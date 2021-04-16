# frozen_string_literal: true

module Mutations
  class CreateSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      model = Slot.new(attributes.to_h)


      {
        slot: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        slot: nil,
        field_errors: invalid.record.errors.messages,
        errors: invalid.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        slot: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        slot: nil,
        field_errors: nil,
        errors: [ error.message ]
      }
    end

    def authorized?(dropzone_id: nil, user_id: nil)
      if user_id != context[:current_resource].id
        required_permission = "createUserSlot"
      else
        required_permission = "createSlot"
      end
      return context[:current_resource].can?(required_permission, dropzone_id: dropzone_id), {
        errors: [
          "You don't have permissions to create ticket addons"
          ]
        }
    end
  end
end
