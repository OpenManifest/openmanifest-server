class Types::Operator::DailyLog::Vehicle < Types::Base::Object
  graphql_name 'DailyLogVehicle'
  field :id, ID, null: true
  field :name, String, null: true
  field :registration, String, null: true
  field :kind, String, null: true, description: "The kind of vehicle (a helicopter, a balloon, a chase vehicle)"
  field :role, Types::Manifest::LoadVehicleRole, null: true, description: "What it did on the load: carried participants or supported the load"
end
