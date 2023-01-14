class Types::Dropzone::MasterLogEntry < Types::Base::Object
  field :date, GraphQL::Types::ISO8601Date, null: true
  field :location, Types::Dropzone::GeocodedLocation, null: true
  field :loads, [Types::Dropzone::MasterLog::Load], null: true
end
