# frozen_string_literal: true

class Types::SellableItemTypes < Types::BaseEnum
  [
    Pack,
    TicketType,
    Extra,
    Slot
  ].map do |model|
    value model.name.camelize(:lower), value: model.name
  end
end
