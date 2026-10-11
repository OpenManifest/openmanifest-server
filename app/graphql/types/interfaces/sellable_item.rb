# frozen_string_literal: true

module Types::Interfaces
  module SellableItem
    include Types::Base::Interface

    field :cost_cents, Int, null: true
    field :cost, Float, null: true, deprecation_reason: "Use costCents, an integer number of cents"
    field :title, String, null: true

    definition_methods do
      def resolve_type(object, context)
        {
          ::TicketType => Types::Dropzone::Ticket,
          ::Extra => Types::Dropzone::Tickets::Addon,
          ::Slot => Types::Manifest::Slot,
        }[object.class]
      end
    end
  end
end
