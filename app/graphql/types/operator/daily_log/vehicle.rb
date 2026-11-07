class Types::Operator::DailyLog::Vehicle < Types::Base::Object
  graphql_name 'DailyLogVehicle'
  field :id, ID, null: true
  field :name, String, null: true
  field :registration, String, null: true
end
