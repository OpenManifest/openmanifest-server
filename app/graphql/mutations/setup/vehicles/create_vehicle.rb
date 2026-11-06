# frozen_string_literal: true

module Mutations::Setup::Vehicles
  class CreateVehicle < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :vehicle, Types::Operator::Vehicle, null: true

    argument :attributes, Types::Input::VehicleInput, required: true

    def resolve(attributes:)
      mutate(
        ::Setup::Vehicles::CreateVehicle,
        :vehicle,
        access_context: access_context_for(attributes[:operator_id]),
        **attributes.to_h.slice(
          :name,
          :min_capacity,
          :capacity,
          :hours,
          :max_payload_kg,
          :registration
        )
      )
    end
  end
end
