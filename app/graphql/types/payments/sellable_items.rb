# frozen_string_literal: true

class Types::Payments::SellableItems < Types::Base::Enum
  [
    Pack,
    TicketType,
    Extra,
    Slot,
  ].map do |model|
    value model.name.camelize(:lower), value: model.name
  end
end
