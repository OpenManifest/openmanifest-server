# frozen_string_literal: true

module Types
  module Input
    class WeatherConditionInput < Types::BaseInputObject
      argument :winds, String, required: false
      argument :temperature, Int, required: false
      argument :jump_run, Int, required: false
      argument :exit_spot_miles, Int, required: false
      argument :offset_miles, Int, required: false
      argument :offset_direction, String, required: false
      argument :dropzone_id, Int, required: true
    end
  end
end
