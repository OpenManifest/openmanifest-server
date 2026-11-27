class Types::Operator::DailyLog::Slot < Types::Base::Object
  graphql_name 'DailyLogSlot'
  field :id, ID, null: false
  field :name, String, null: true
  field :phone, String, null: true
  field :email, String, null: true
  field :emergency_contact, String, null: true, description: "The person's own, or for a guest without one their escort's name and phone"
  field :ticket_type, String, null: true, description: "The ticket's name"
  field :escort, String, null: true, description: "For a guest: the name of the member they came with"
  field :altitude_m, Float, null: true, description: 'Metres'
  field :activity_type, String, null: true
end
