# frozen_string_literal: true

module Mutations::Setup::Vehicles
  class UpdateVehicle < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :vehicle, Types::Operator::Vehicle, null: true

    argument :attributes, Types::Input::VehicleInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      model = Vehicle.find(id)

      # A vehicle never moves to another operator
      model.update!(attributes.to_h.except(:operator_id))
      {
        vehicle: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        vehicle: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        vehicle: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        vehicle: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      if context[:current_resource].can?(
        "updateVehicle",
        operator_id: Vehicle.find(id).operator_id
      )
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to update this vehicle",
            ],
          },
        ]
      end
    end
  end
end
