# frozen_string_literal: true

module Mutations::Manifest
  class MoveSlot < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true
    field :loads, [Types::LoadType], null: true

    argument :source_slot, Integer, required: true,
                                    prepare: -> (value, ctx) { Slot.find_by(id: value) }
    argument :target_load, Integer, required: true,
                                    prepare: -> (value, ctx) { Load.find_by(id: value) }
    argument :target_slot, Integer, required: false,
                                    prepare: -> (value, ctx) { Slot.find_by(id: value) }

    def resolve(target_load: nil, source_slot: nil, target_slot: nil)
      mutate(
        Manifest::MoveSlot,
        :loads,
        access_context: access_context_for(
          source_slot.dropzone
        ),
        source_slot: source_slot,
        target_slot: target_slot,
        target_load: target_load
      )
    end
  end
end
