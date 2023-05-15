class Resolvers::Meta::Location < Resolvers::Base
  type ::Types::Meta::Locations::Location, null: true
  description "Find address by searching Google Places"

  argument :id, ID, required: false,
                    description: 'Local ID of location'
  argument :place_id, ID, required: false,
                          description: 'Google Place ID'

  def resolve(id: nil, place_id: nil)
    return ::Location.find_by(id: id) if id
    return nil unless place_id
    location = ::Location.find_or_initialize_by(place_id: place_id)
    location.save if location.new_record?
    location
  end
end
