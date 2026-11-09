# frozen_string_literal: true

module Types
  module Input
    class LoadVehicleInput < Types::Base::Input
      argument :vehicle_id, GraphQL::Types::ID, required: true
      argument :role, Types::Manifest::LoadVehicleRole, required: false, default_value: "carrying"
    end
  end
end
