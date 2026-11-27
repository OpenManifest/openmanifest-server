# frozen_string_literal: true

class Types::Manifest::LoadVehicleRole < Types::Base::Enum
  graphql_name "LoadVehicleRole"

  value "carrying", "Carries participants; its seats count towards the load's capacity"
  value "support", "Supports the load (a tug, a chase vehicle, a shuttle); has no participants"
end
