class Types::Operator::MasterLog::Load < Types::Base::Object
  graphql_name 'MasterLogLoad'
  field :id, ID, null: false
  field :load_number, Integer, null: true
  field :dispatch_at, GraphQL::Types::ISO8601DateTime, null: true
  field :gca, Types::Operator::MasterLog::User, null: true
  field :load_master, Types::Operator::MasterLog::User, null: true
  field :pilot, Types::Operator::MasterLog::User, null: true
  field :aircraft, Types::Operator::MasterLog::Aircraft, null: true
  field :slots, [Types::Operator::MasterLog::Slot], null: true
end
