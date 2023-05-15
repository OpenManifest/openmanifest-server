class Types::Meta::Locations::Coordinates < Types::Base::Object
  description 'Coordinates of a location for displaying on a map'
  field :lat, Float, null: true
  field :lng, Float, null: true
end
