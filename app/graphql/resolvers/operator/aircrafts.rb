# frozen_string_literal: true

class Resolvers::Operator::Aircrafts < Resolvers::Base
  type [Types::Operator::Aircraft], null: true
  description "Get Aircrafts for an operator"
  operator :operator, required: true

  def resolve(operator: nil)
    return nil unless operator

    authorize_operator!(operator)
    query = operator.planes.kept

    query.order(name: :asc)
  end
end
