# frozen_string_literal: true

module Types::Dropzone::Weather
  class Condition < Types::Base::Object
    graphql_name 'WeatherCondition'
    field :id, GraphQL::Types::ID, null: false
    field :winds, [Types::Dropzone::Weather::Wind], null: true
    def winds
      JSON.parse(object.winds || "[]")
    end

    field :temperature, Int, null: true
    field :jump_run, Int, null: true
    field :exit_spot_miles, Int, null: true
    field :offset_miles, Int, null: true
    field :offset_direction, Int, null: true
    timestamp_fields
  end
end
