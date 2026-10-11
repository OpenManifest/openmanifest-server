class Types::Operator::MasterLog::MasterLogInput < Types::Base::Input
  argument :notes, String, required: false
  argument :dzso, ID, required: false,
                      prepare: -> (value, ctx) { Membership.find_by(id: value) }
end
