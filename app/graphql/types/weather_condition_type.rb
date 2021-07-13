module Types
  class WeatherConditionType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :winds, [Types::WindType], null: true
    def winds
      JSON.parse(object.winds || '[]')
    end

    field :temperature, Int, null: true
    field :jump_run, Int, null: true
    field :exit_spot_miles, Int, null: true
    field :offset_miles, Int, null: true
    field :offset_direction, Int, null: true
    field :created_at, Int, null: false
    field :updated_at, Int, null: false
  end
end