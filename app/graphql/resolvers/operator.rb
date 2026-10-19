# frozen_string_literal: true

class Resolvers::Operator < Resolvers::Base
  type Types::OperatorType, null: true
  description "Get operator details"
  argument :id, GraphQL::Types::ID, required: true

  def resolve(id:)
    query = context[:access_context].operators
    query.find_by(id: id)
  end
end
