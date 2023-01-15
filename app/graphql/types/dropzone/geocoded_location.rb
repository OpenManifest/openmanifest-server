# frozen_string_literal: true

module Types::Dropzone
  class GeocodedLocation < Types::Base::Object
    field :id, GraphQL::Types::ID, null: true
    field :formatted_string, String, null: true
    field :lat, Float, null: true
    field :lng, Float, null: false
  end
end
