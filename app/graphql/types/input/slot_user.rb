# frozen_string_literal: true

module Types
  module Input
    class SlotUser < Types::BaseInputObject
      argument :id, Int, required: true
      argument :exit_weight, Float, required: true
      argument :rig_id, Int, required: false
      argument :passenger_name, String, required: false
      argument :passenger_exit_weight, Float, required: false
    end
  end
end
