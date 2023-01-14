# frozen_string_literal: true

class Types::Payments::OrderState < Types::Base::Enum
  Order.states.each do |name,|
    value name.to_s, name.to_s
  end
end
