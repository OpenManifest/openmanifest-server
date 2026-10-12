# frozen_string_literal: true

class Types::Operator::State < Types::Base::Enum
  graphql_name "OperatorState"
  ::Operator.state_machine.states.keys.each do |state|
    value state
  end
end
