# frozen_string_literal: true

module Mutations
  class DeleteSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Slot.find(id)

      model.passenger_slot.destroy if model.has_passenger?

      ::Transactions::Refund.run(order: model.order)
      model.order.update(state: :cancelled)
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
      dropzone = slot.load.plane.dropzone
      dz_user = context[:current_resource].dropzone_users.find_by(dropzone: dropzone)

      is_current_user = dz_user.id == slot.dropzone_user_id

      if slot.load.has_landed?
        return false, {
          errors: ["You can't take slots off a load that has landed"]
        }
      elsif dz_user.can?(
        is_current_user ? :deleteSlot : :deleteUserSlot,
      )
        true
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
