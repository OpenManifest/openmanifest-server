# frozen_string_literal: true

module Mutations::Manifest
  class DeleteSlot < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true
    field :slot, Types::SlotType, null: true

    argument :id, Int, required: true

    def resolve(id:)
      mutate(
        ::Manifest::DeleteSlot,
        :slot,
        slot: slot_by_id(id),
        access_context: access_context_for(
          slot_by_id(id).load.dropzone
        )
      )
    end

    def slot_by_id(id)
      @slot_by_id ||= Slot.find(id)
    end
  end
end
