class Types::Operator::DailyLog::Load < Types::Base::Object
  graphql_name 'DailyLogLoad'
  field :id, ID, null: false
  field :load_number, Integer, null: true
  field :name, String, null: true
  field :dispatch_at, GraphQL::Types::ISO8601DateTime, null: true
  field :departed_at, GraphQL::Types::ISO8601DateTime, null: true
  field :completed_at, GraphQL::Types::ISO8601DateTime, null: true
  field :crew, [Types::Operator::DailyLog::Crew], null: true
  field :destinations, [String], null: true, description: "Names of the places the load went to"
  field :gca, Types::Operator::DailyLog::User, null: true
  field :load_master, Types::Operator::DailyLog::User, null: true
  field :pilot, Types::Operator::DailyLog::User, null: true
  field :vehicle, Types::Operator::DailyLog::Vehicle, null: true
  field :slots, [Types::Operator::DailyLog::Slot], null: true
end
