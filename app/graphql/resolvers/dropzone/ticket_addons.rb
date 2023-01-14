# frozen_string_literal: true

class Resolvers::Dropzone::TicketAddons < Resolvers::Base
  description "Get all ticket type extras"
  type [Types::Dropzone::Tickets::Addon], null: false
  argument :dropzone, GraphQL::Types::ID, required: false,
                                          prepare: -> (value, ctx) { ::Dropzone.find_by(id: value) }
  argument :ticket_type, GraphQL::Types::ID, required: false,
                                             prepare: -> (value, ctx) { ::TicketType.find_by(id: value) }

  def resolve(dropzone: nil, ticket_type: nil, lookahead: nil)
    return nil unless dropzone || ticket_type
    query = dropzone.extras if dropzone
    query = ticket_type.extras if ticket_type
    query = query.includes(ticket_type_extras: :ticket_type) if lookahead.selects?(:ticket_types)
    query.order(name: :asc)
  end
end
