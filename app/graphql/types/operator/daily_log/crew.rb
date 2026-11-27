class Types::Operator::DailyLog::Crew < Types::Base::Object
  graphql_name 'DailyLogCrew'
  description "A member on the crew of a load, by the operator's name of the role"
  field :id, ID, null: true
  field :role, String, null: true
  field :name, String, null: true
  field :phone, String, null: true
end
