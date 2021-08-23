# frozen_string_literal: true

class Types::OrderStateType < Types::BaseEnum
  Order.states.each do |name,|
    value name.to_s, name.to_s
  end
end
