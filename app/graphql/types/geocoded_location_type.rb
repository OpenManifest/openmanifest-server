# frozen_string_literal: true

module Types
  class GeocodedLocationType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :formatted_string, String, null: true
    field :lat, Float, null: true
    field :lng, Float, null: false
  end
end
