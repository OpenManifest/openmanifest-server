# frozen_string_literal: true

module Mutations::Manifest
  class UpdateSlot < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :slot, Types::Manifest::Slot, null: true

    argument :attributes, Types::Input::SlotInput, required: true
    argument :id, Int, required: true

    # What can be edited on a slot: who jumps and on which load is not among it (a slot is moved with moveSlot, which
    # checks capacity, credits and the target's operator)
    UPDATABLE = %i(ticket_type activity_type destination load_vehicle rig body_mass_kg group_number extras lock_version).freeze

    def resolve(attributes:, id:)
      model = Slot.find(id)
      values = attributes.to_h.slice(*UPDATABLE)
      operator_id = model.load.operator_id

      return { slot: nil, field_errors: nil, errors: ["The ticket must belong to the same operator"] } if values[:ticket_type] && values[:ticket_type].operator_id != operator_id

      values[:extras] = values[:extras].where(operator_id: operator_id) if values[:extras]
      model.update!(values.compact)

      {
        slot: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::StaleObjectError
      raise GraphQL::ExecutionError.new("This slot was changed by someone else", extensions: { code: "CONFLICT" })
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
      slot = Slot.find_by(id: id)
      return [false, { errors: ["Slot not found"] }] unless slot

      is_current_user = slot&.membership.present? && context[:current_resource].id == slot.membership.user_id

      if context[:current_resource].can?(
        is_current_user ? "updateSlot" : "updateUserSlot",
        operator_id: slot.load.operator_id
      )
        true
      else
        membership = slot.membership
        [
          false, {
            errors: if is_current_user && membership.manifest_desk_only?(:updateSlot)
                      [Membership::MANIFEST_DESK_MESSAGE]
                    elsif is_current_user
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
