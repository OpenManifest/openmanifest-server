# frozen_string_literal: true

module Types
  module Input
    class VehicleInput < Types::Base::Input
      argument :name, String, required: false
      argument :min_capacity, Int, required: false
      argument :capacity, Int, required: false
      argument :operator_id, Int, required: false
      argument :hours, Int, required: false
      argument :next_maintenance_hours, Int, required: false
      argument :registration, String, required: false
    end
  end
end
