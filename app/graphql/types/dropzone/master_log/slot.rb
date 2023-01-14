class Types::Dropzone::MasterLog::Slot < Types::Base::Object
  graphql_name 'MasterLogSlot'
  field :id, ID, null: false
  field :name, String, null: true
  field :altitude, Integer, null: true
  field :jump_type, String, null: true
end
