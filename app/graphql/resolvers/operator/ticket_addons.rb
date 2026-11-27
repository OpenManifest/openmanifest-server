# frozen_string_literal: true

class Resolvers::Operator::TicketAddons < Resolvers::Base
  description "Get all ticket type extras"
  type [Types::Operator::Tickets::Addon], null: false
  operator :operator, required: false
  argument :ticket_type, GraphQL::Types::ID, required: false,
                                             prepare: -> (value, ctx) { ::TicketType.find_by(id: value) }

  def resolve(operator: nil, ticket_type: nil)
    return nil unless operator || ticket_type
    operator ||= ticket_type.operator
    authorize_operator!(operator)
    query = operator.extras
    query.order(name: :asc)
  end
end
