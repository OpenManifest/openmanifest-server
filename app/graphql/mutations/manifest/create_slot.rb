# frozen_string_literal: true

module Mutations::Manifest
  class CreateSlot < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :slot, Types::Manifest::Slot, null: true

    argument :attributes, Types::Input::SlotInput, required: true

    def resolve(attributes:)
      mutate(
        Manifest::CreateSlot,
        :slot,
        access_context: access_context_for(
          attributes[:membership].operator
        ),
        **attributes.to_h.slice(
          :ticket_type,
          :membership,
          :activity_type,
          :destination,
          :load_vehicle,
          :body_mass_kg,
          :load,
          :group_number,
          :guest_name,
          :guest_body_mass_kg,
        ),
        extra_ids: attributes[:extras]&.pluck(:id),
        equipment_ids: attributes[:equipment]&.pluck(:id)
      )
    end
  end
end
