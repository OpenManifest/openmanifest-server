# frozen_string_literal: true

module Types
  module Input
    class WeatherConditionInput < Types::Base::Input
      argument :winds, String, required: false,
                               description: "JSON: [{ altitude_m, speed_mps, direction, temperature_c }]"
      argument :temperature_c, Float, required: false
      argument :jump_run, Int, required: false
      argument :exit_spot_m, Float, required: false
      argument :offset_m, Float, required: false
      argument :offset_direction, String, required: false
      argument :operator_id, Int, required: true
    end
  end
end
