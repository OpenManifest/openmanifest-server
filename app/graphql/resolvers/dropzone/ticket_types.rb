# frozen_string_literal: true

class Resolvers::Dropzone::TicketTypes < Resolvers::Base
  description "Get ticket types for a dropzone"
  type [Types::Dropzone::Ticket], null: true
  argument :allow_manifesting_self, Boolean, required: false
  dropzone :dropzone, required: true

  def resolve(
    dropzone: nil,
    allow_manifesting_self: nil,
    lookahead: nil
  )
    query = apply_lookaheads(lookahead, dropzone.ticket_types)
    query = query.where(allow_manifesting_self: allow_manifesting_self) if allow_manifesting_self

    query.order(name: :asc)
  end
end
