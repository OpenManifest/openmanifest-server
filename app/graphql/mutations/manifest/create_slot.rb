# frozen_string_literal: true

module Mutations::Manifest
  class CreateSlot < Mutations::BaseMutation
    field :slot, Types::SlotType, null: true
    field :errors, [String], null: true
    field :field_errors, [Types::FieldErrorType], null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      mutate(
        Manifest::CreateSlot,
        :slot,
        access_context: access_context_for(
          attributes[:dropzone_user].dropzone
        ),
        **attributes.to_h.slice(
          :ticket_type,
          :dropzone_user,
          :jump_type,
          :exit_weight,
          :rig,
          :load,
          :group_number,
          :extras,
          :passenger_name,
          :passenger_exit_weight,
        )
      )
    end
  end
end
