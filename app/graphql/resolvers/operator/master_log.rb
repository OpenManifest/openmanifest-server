# frozen_string_literal: true

class Resolvers::Operator::MasterLog < Resolvers::Base
  description "Get the master log entry for a specific day"
  type Types::Operator::MasterLogEntry, null: true

  operator :operator, required: true

  argument :date, GraphQL::Types::ISO8601Date,
           required: true,
           prepare: -> (value, ctx) { value.to_date }

  def resolve(
    operator: nil,
    date: nil
  )
    return nil unless operator

    # The same permission that lets a user write the master log (and that shows its menu entry in the app)
    authorize_operator!(operator, :updateOperator)
    operator.master_logs.at(date)
  end
end
