# frozen_string_literal: true

class Types::Operator::StateEvent < Types::Base::Enum
  graphql_name "OperatorStateEvent"
  ::Operator.state_machine.events.keys.each do |state|
    value state.to_s, state.to_s
  end
end
