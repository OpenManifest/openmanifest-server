# frozen_string_literal: true

module Types
  class SellableItemType < Types::BaseUnion
    possible_types Types::TicketTypeType,
                   Types::SlotType,
                   Types::ExtraType

    # Determine what object type to use for `object`
    def self.resolve_type(object, context)
      {
        TicketType => Types::TicketTypeType,
        Extra => Types::ExtraType,
        Slot => Types::SlotType,
      }[object.class]
    end
  end
end
