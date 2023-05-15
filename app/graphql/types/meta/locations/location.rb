class Types::Meta::Locations::Location < Types::Base::Object
  field :id, ID, null: false
  field :full_address, String, null: true
  field :street_address, String, null: true
  field :place_id, String, null: false
  field :state, String, null: true
  field :country, String, null: true
  field :city, String, null: true
  field :post_code, String, null: true
  field :coordinates, Types::Meta::Locations::Coordinates, null: true

  def coordinates
    object.slice(:lat, :lng)
  end
end
