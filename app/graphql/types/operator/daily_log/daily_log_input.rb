class Types::Operator::DailyLog::DailyLogInput < Types::Base::Input
  argument :notes, String, required: false
  argument :duty_officer, ID, required: false,
                              prepare: -> (value, ctx) { Membership.find_by(id: value) }
end
