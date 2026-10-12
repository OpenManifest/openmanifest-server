class Types::Operator::DailyLog::Slot < Types::Base::Object
  graphql_name 'DailyLogSlot'
  field :id, ID, null: false
  field :name, String, null: true
  field :altitude, Integer, null: true
  field :activity_type, String, null: true
end
