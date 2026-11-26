# frozen_string_literal: true

module Types::Manifest
  # A vehicle of a load, with the role it has there (P7.9)
  class LoadVehicle < Types::Base::Object
    graphql_name "LoadVehicle"
    implements Types::Interfaces::Polymorphic

    field :id, GraphQL::Types::ID, null: false
    field :role, Types::Manifest::LoadVehicleRole, null: false
    field :position, Int, null: false
    field :capacity, Int, null: false, description: "The seats it offers participants (0 for a support vehicle)"
    field :slots_count, Int, null: false, description: "The slots assigned to this vehicle"
    field :available_slots, Int, null: false
    async_field :vehicle, Types::Operator::Vehicle, null: false
  end
end
