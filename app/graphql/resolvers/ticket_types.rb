# frozen_string_literal: true

class Resolvers::TicketTypes < Resolvers::Base
  description "Get ticket types for a dropzone"
  type [Types::TicketTypeType], null: true
  argument :dropzone, Int, required: true,
           prepare: -> (value, ctx) { Dropzone.find_by(id: value) }
  argument :allow_manifesting_self, Boolean, required: false

  def resolve(
    dropzone: nil,
    allow_manifesting_self: nil,
    lookahead: nil
  )
    query = dropzone.ticket_types
    query = query.includes(ticket_type_extras: :extra)                  if lookahead.selects?(:extras)
    query = query.where(allow_manifesting_self: allow_manifesting_self) if allow_manifesting_self

    query.order(name: :asc)
  end
end
