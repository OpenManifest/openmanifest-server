# frozen_string_literal: true

module Mutations::Manifest
  class MoveSlot < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :loads, [Types::Manifest::Load], null: true

    argument :source_slot, Integer, required: true,
                                    prepare: -> (value, ctx) { Slot.find_by(id: value) }
    argument :target_load, Integer, required: true,
                                    prepare: -> (value, ctx) { Load.find_by(id: value) }
    argument :target_slot, Integer, required: false,
                                    prepare: -> (value, ctx) { Slot.find_by(id: value) }

    argument :target_load_vehicle, Integer, required: false,
                                            prepare: -> (value, ctx) { LoadVehicle.find_by(id: value) },
                                            description: "The vehicle of the target load the slot rides in"

    def resolve(target_load: nil, source_slot: nil, target_slot: nil, target_load_vehicle: nil)
      mutate(
        Manifest::MoveSlot,
        :loads,
        access_context: access_context_for(
          source_slot.operator
        ),
        source_slot: source_slot,
        target_slot: target_slot,
        target_load: target_load,
        target_load_vehicle: target_load_vehicle
      )
    end
  end
end
