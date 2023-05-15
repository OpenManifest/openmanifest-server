class Types::Meta::Locations::GooglePlace < Types::Base::Object
  field :id, ID, null: false, method: :place_id
  field :address, String, null: true
end
