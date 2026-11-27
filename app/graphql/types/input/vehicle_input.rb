# frozen_string_literal: true

module Types
  module Input
    class VehicleInput < Types::Base::Input
      argument :name, String, required: false
      argument :min_capacity, Int, required: false
      argument :capacity, Int, required: false
      argument :operator_id, Int, required: false
      argument :max_payload_kg, Float, required: false
      argument :hours, Int, required: false
      argument :next_maintenance_hours, Int, required: false
      argument :registration, String, required: false
      argument :kind, String, required: false, description: "One of the operator's vehicle kinds (a helicopter or an aeroplane, a balloon or its chase vehicle); the main kind when left out"
    end
  end
end
