# frozen_string_literal: true

class Resolvers::Dropzone::TicketTypes < Resolvers::Base
  description "Get ticket types for a dropzone"
  type [Types::Dropzone::Ticket], null: true
  argument :allow_manifesting_self, Boolean, required: false
  argument :dropzone, GraphQL::Types::ID, required: true,
                                          prepare: -> (value, ctx) { ::Dropzone.find_by(id: value) }

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
