# frozen_string_literal: true

module Mutations::Setup::Vehicles
  class DeleteVehicle < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :vehicle, Types::Operator::Vehicle, null: true

    argument :id, Int, required: true

    def resolve(id:)
      model = Vehicle.find(id)

      model.discard!

      {
        vehicle: model.reload,
        field_errors: nil,
        errors: nil,
      }
    rescue Discard::RecordNotDiscarded
      # Failed save, return the errors to the client
      {
        vehicle: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: ["Failed to archive this vehicle"],
      }

    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        vehicle: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        vehicle: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        vehicle: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      vehicle = Vehicle.find(id)

      if context[:current_resource].can?(
        :deleteVehicle,
        operator_id: vehicle.operator_id
      )
        true
      else
        [
          false, {
            errors: ["You cant delete this vehicle"],
          },
        ]
      end
    end
  end
end
