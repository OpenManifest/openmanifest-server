# frozen_string_literal: true

module Mutations
  class CreateSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      model = Slot.find_or_initialize_by(
        user_id: attributes[:user_id],
        load_id: attributes[:load_id],
      )
      model.assign_attributes(attributes.to_h)

      model.save!

      {
        slot: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        slot: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
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

    def authorized?(attributes: nil)
      if attributes[:user_id] != context[:current_resource].id
        required_permission = "createUserSlot"
      else
        required_permission = "createSlot"
      end

      dropzone = Load.find(attributes[:load_id]).plane.dropzone
      if context[:current_resource].can?(required_permission, dropzone_id: dropzone.id)
        return true
      else
        return false, {
          errors: [
            "You don't have permissions to manifest other users #{required_permission}"
            ]
          }
      end
    end
  end
end
