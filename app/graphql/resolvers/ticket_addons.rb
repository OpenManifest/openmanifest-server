# frozen_string_literal: true

class Resolvers::TicketAddons < Resolvers::Base
  description "Get all ticket type extras"
  type [Types::ExtraType], null: false
  argument :dropzone, Int, required: true,
           prepare: -> (value, ctx) { Dropzone.find_by(id: value) }

  def resolve(dropzone: nil, lookahead: nil)
    query = dropzone.extras
    query = query.includes(ticket_type_extras: :ticket_type) if lookahead.selects?(:ticket_types)
    query.order(name: :asc)
  end
end
