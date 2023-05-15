class Resolvers::Meta::Locations < Resolvers::Base
  type [Types::Meta::Locations::GooglePlace], null: true
  description "Find address by searching Google Places"

  argument :search, String, required: true

  def resolve(search: "")
    return if search.blank?
    result = ::Geocoder.search(search)

    result.map do |address|
      {
        address: address.data.dig('formatted_address'),
        place_id: address.data.dig('place_id'),
      }
    end
  end
end
