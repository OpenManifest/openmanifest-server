# frozen_string_literal: true

class Resolvers::Operator::TicketTypes < Resolvers::Base
  description "Get ticket types for an operator"
  type [Types::Operator::Ticket], null: true
  argument :allow_manifesting_self, Boolean, required: false
  operator :operator, required: true

  def resolve(
    operator: nil,
    allow_manifesting_self: nil
  )
    authorize_operator!(operator)
    query = operator.ticket_types
    query = query.where(allow_manifesting_self: allow_manifesting_self) if allow_manifesting_self

    query.order(name: :asc)
  end
end
