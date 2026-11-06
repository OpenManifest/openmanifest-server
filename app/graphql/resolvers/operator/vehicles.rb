# frozen_string_literal: true

class Resolvers::Operator::Vehicles < Resolvers::Base
  type [Types::Operator::Vehicle], null: true
  description "Get Vehicles for an operator"
  operator :operator, required: true

  def resolve(operator: nil)
    return nil unless operator

    authorize_operator!(operator)
    query = operator.vehicles.kept

    query.order(name: :asc)
  end
end
