# frozen_string_literal: true

module Types
  module SellableItemType
    include Types::BaseInterface
    field :cost, Float, null: true
    field :title, String, null: true

    definition_methods do
      def resolve_type(object, context)
        {
          ::TicketType => Types::TicketTypeType,
          ::Extra => Types::ExtraType,
          ::Slot => Types::SlotType,
        }[object.class]
      end
    end
  end
end
