# frozen_string_literal: true

module Types::Operator::Weather
  class Condition < Types::Base::Object
    graphql_name 'WeatherCondition'
    field :id, GraphQL::Types::ID, null: false
    field :winds, [Types::Operator::Weather::Wind], null: true
    def winds
      object.wind_list
    end

    field :temperature_c, Float, null: true, description: "Degrees Celsius"
    def temperature_c = object.temperature_c&.to_f

    field :jump_run, Int, null: true
    field :exit_spot_m, Float, null: true, description: "Metres"
    def exit_spot_m = object.exit_spot_m&.to_f

    field :offset_m, Float, null: true, description: "Metres"
    def offset_m = object.offset_m&.to_f

    field :offset_direction, Int, null: true
    timestamp_fields
  end
end
