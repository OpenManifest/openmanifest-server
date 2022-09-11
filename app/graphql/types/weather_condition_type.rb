# frozen_string_literal: true

module Types
  class WeatherConditionType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :winds, [Types::WindType], null: true
    def winds
      JSON.parse(object.winds || "[]")
    end

    field :temperature, Int, null: true
    field :jump_run, Int, null: true
    field :exit_spot_miles, Int, null: true
    field :offset_miles, Int, null: true
    field :offset_direction, Int, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
