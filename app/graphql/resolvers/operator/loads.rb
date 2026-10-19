# frozen_string_literal: true

class Resolvers::Operator::Loads < Resolvers::Base
  type Types::Manifest::Load.connection_type, null: false
  description "Get all loads"

  argument :date, GraphQL::Types::ISO8601Date, required: false,
                                               prepare: -> (value, ctx) { value.to_date },
                                               description: "Search for loads for a specific day"
  argument :operator, GraphQL::Types::ID, required: true,
                                          prepare: -> (value, ctx) { ::Operator.find_by(id: value) }
  def resolve(operator: nil, earliest_timestamp: nil, date: nil)
    return nil unless operator

    authorize_operator!(operator)
    query = operator.loads
    Time.use_zone(operator.time_zone) do
      query = query.where(loads: { created_at: date.all_day }) unless date.nil?
      query.order(created_at: :desc)
    end
  end
end
