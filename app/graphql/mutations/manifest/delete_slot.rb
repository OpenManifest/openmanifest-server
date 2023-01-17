# frozen_string_literal: true

module Mutations::Manifest
  class DeleteSlot < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :slot, Types::Manifest::Slot, null: true

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
      @slot_by_id ||= Slot.find_by(id: id)
    end
  end
end
