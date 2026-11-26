class Types::Operator::DailyLog::User < Types::Base::Object
  graphql_name 'DailyLogUser'
  field :id, ID, null: true
  field :name, String, null: true
  field :nickname, String, null: true
  field :phone, String, null: true
  field :email, String, null: true
end
