# frozen_string_literal: true

class Resolvers::Meta::Federations < Resolvers::Base
  type [Types::FederationType], null: false
  description "Get all available federations"

  def resolve(lookahead: nil)
    query = Federation.all
    query = query.includes(:licenses) if lookahead.selects?(:licenses)
    query.order(name: :asc)
  end
end
