# frozen_string_literal: true

module Types
  module Input
    class LoadCrewInput < Types::Base::Input
      argument :crew_role_id, GraphQL::Types::ID, required: true
      argument :membership_id, GraphQL::Types::ID, required: true
      argument :load_vehicle_id, GraphQL::Types::ID, required: false, description: "The vehicle of the load (its LoadVehicle), for a role per vehicle"
      argument :vehicle_id, GraphQL::Types::ID, required: false, description: "Or the vehicle itself, when the load is new or changes its vehicles"
    end
  end
end
