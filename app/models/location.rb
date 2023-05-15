class Location < ApplicationRecord
  acts_as_mappable
  before_save :prepopulate

  protected

  # Check how we should prepopulate these fields
  # Priority:
  # 1. Place ID
  # 2. Full address
  # 3. Lat/Lng
  def prepopulate
    return populate_from_place_id     if place_id
    return populate_from_address      if full_address
    return populate_from_coordinates  if lat && lng
  end

  # Fill out all fields from only place_id
  #
  # @return [void]
  def populate_from_place_id
    return unless place_id
    result = Geocoder.search(
      place_id,
      google_place_id: true,
      lookup: :google
    )
    return unless result&.first&.data
    response = Geokit::Geocoders::GoogleGeocoder.single_json_to_geoloc(result.first.data)
    return unless response
    assign_from_geokit(response)
  end

  # Fill out lat/lng from full address
  #
  # @return [void]
  def populate_from_coordinates
    return unless lat
    return unless lng
    response = Geokit::Geocoders::GoogleGeocoder.reverse_geocode("#{lat},#{lng}")
    return unless response&.success
    assign_from_gekit(response)
  end

  # Fill out all fields from only lat/lng
  #
  # @return [void]
  def populate_from_address
    return unless full_address
    response = Geokit::Geocoders::GoogleGeocoder.geocode(full_address)
    return unless response&.success
    assign_from_gekit(response)
  end

  # Assign fields from a Geokit::Geoloc object
  #
  # @param [Geokit::Geoloc] response
  def assign_from_geokit(response)
    return unless response
    assign_attributes(
      lat: response.lat,
      lng: response.lng,
      street_address: response.street_address,
      full_address: response.full_address,
      city: response.city,
      country: response.country,
      place_id: response.place_id,
      state: response.state_code,
      post_code: response.zip
    )
  end
end
