class Types::Dropzone::MasterLog::Aircraft < Types::Base::Object
  graphql_name 'MasterLogAircraft'
  field :name, String, null: true
  field :registration, String, null: true
end
