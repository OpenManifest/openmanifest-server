# frozen_string_literal: true

class Resolvers::Dropzone::TicketAddons < Resolvers::Base
  description "Get all ticket type extras"
  type [Types::Dropzone::Tickets::Addon], null: false
  dropzone :dropzone, required: false
  argument :ticket_type, GraphQL::Types::ID, required: false,
                                             prepare: -> (value, ctx) { ::TicketType.find_by(id: value) }

  def resolve(dropzone: nil, ticket_type: nil, lookahead: nil)
    return nil unless dropzone || ticket_type
    dropzone ||= ticket_type.dropzone
    query = apply_lookaheads(lookahead, dropzone.extras)
    query.order(name: :asc)
  end
end
