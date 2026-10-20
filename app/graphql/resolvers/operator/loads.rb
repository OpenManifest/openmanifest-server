# frozen_string_literal: true

class Resolvers::Operator::Loads < Resolvers::Base
  type Types::Manifest::Load.connection_type, null: false
  description "Get all loads"

  argument :date, GraphQL::Types::ISO8601Date, required: false,
                                               prepare: -> (value, ctx) { value.to_date },
                                               description: "Search for loads for a specific day"
  argument :from, GraphQL::Types::ISO8601Date, required: false, prepare: -> (value, ctx) { value.to_date },
                                               description: "Loads for this day and the days after it"
  argument :to, GraphQL::Types::ISO8601Date, required: false, prepare: -> (value, ctx) { value.to_date },
                                             description: "Loads for this day and the days before it"
  argument :operator, GraphQL::Types::ID, required: true,
                                          prepare: -> (value, ctx) { ::Operator.find_by(id: value) }
  def resolve(operator: nil, earliest_timestamp: nil, date: nil, from: nil, to: nil)
    return nil unless operator

    authorize_operator!(operator)
    query = operator.loads
    # The day a load is for (a load scheduled ahead is for a day that has not come), in the operator's own time zone
    query = query.where(load_date: date) unless date.nil?
    query = query.where(load_date: from..) unless from.nil?
    query = query.where(load_date: ..to) unless to.nil?
    query.order(load_date: :desc, created_at: :desc)
  end
end
