# frozen_string_literal: true

module Types::Dropzone
  class GeocodedLocation < Types::Base::Object
    field :formatted_string, String, null: true
    field :id, GraphQL::Types::ID, null: false
    field :lat, Float, null: true
    field :lng, Float, null: false
  end
end
