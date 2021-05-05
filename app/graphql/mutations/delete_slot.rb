# frozen_string_literal: true

module Mutations
  class DeleteSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Slot.find(id)

      model.destroy
      {
        slot: model,
        field_errors: nil,
        errors: nil
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

    def authorized?(id: nil, attributes: nil)
      slot = Slot.find(id)

      is_current_user = context[:current_resource].id == slot.user_id

      if context[:current_resource].can?(
        is_current_user ? :deleteSlot : :deleteUserSlot,
        dropzone_id: Slot.find(id).load.plane.dropzone_id
      )
        return true
      else 
        return false, {
          errors: if is_current_user
                    ["You cant take yourself off the load"]
                  else
                    ["You cant take somebody else off the load"]
                  end
          }
      end
    end
  end
end
