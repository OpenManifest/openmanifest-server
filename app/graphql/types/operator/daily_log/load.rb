class Types::Operator::DailyLog::Load < Types::Base::Object
  graphql_name 'DailyLogLoad'
  field :id, ID, null: false
  field :load_number, Integer, null: true
  field :dispatch_at, GraphQL::Types::ISO8601DateTime, null: true
  field :gca, Types::Operator::DailyLog::User, null: true
  field :load_master, Types::Operator::DailyLog::User, null: true
  field :pilot, Types::Operator::DailyLog::User, null: true
  field :vehicle, Types::Operator::DailyLog::Vehicle, null: true
  field :slots, [Types::Operator::DailyLog::Slot], null: true
end
