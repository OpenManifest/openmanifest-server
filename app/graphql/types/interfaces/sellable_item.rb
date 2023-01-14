# frozen_string_literal: true

module Types::Interfaces
  module SellableItem
    include Types::Base::Interface
    field :cost, Float, null: true
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
