# frozen_string_literal: true

module Mutations::Manifest
  class UpdateSlot < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :slot, Types::Manifest::Slot, null: true

    argument :attributes, Types::Input::SlotInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      model = Slot.find(id)

      model.update(attributes.to_h)

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
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        slot: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        slot: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      slot = Slot.find(id)

      is_current_user = context[:current_resource].id == slot.user_id

      if context[:current_resource].can?(
        is_current_user ? "updateSlot" : "updateUserSlot",
        dropzone_id: Slot.find(id).load.plane.dropzone_id
      )
        true
      else
        [
          false, {
            errors: if is_current_user
                      ["You cant modify a manifested slot"]
                    else
                      ["You cant modify somebody elses slot"]
                    end,
          },
        ]
      end
    end
  end
end
