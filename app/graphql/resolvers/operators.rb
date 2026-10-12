# frozen_string_literal: true

class Resolvers::Operators < Resolvers::Base
  type Types::OperatorType.connection_type, null: false
  description "Get all available operators"

  argument :state, [Types::Operator::State], required: false,
                                             default_value: nil
  def resolve(
    state: nil
  )
    query = context[:access_context].operators
    query = query.where(state: state.map(&:to_s)) if state.present?

    query.distinct.order(id: :asc)
  end
end
