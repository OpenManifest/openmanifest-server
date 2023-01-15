class Types::Dropzone::MasterLog::Load < Types::Base::Object
  graphql_name 'MasterLogLoad'
  field :id, ID, null: false
  field :load_number, Integer, null: true
  field :dispatch_at, GraphQL::Types::ISO8601DateTime, null: true
  field :gca, Types::Dropzone::MasterLog::User, null: true
  field :load_master, Types::Dropzone::MasterLog::User, null: true
  field :pilot, Types::Dropzone::MasterLog::User, null: true
  field :aircraft, Types::Dropzone::MasterLog::Aircraft, null: true
  field :slots, [Types::Dropzone::MasterLog::Slot], null: true
end
