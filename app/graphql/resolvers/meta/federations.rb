# frozen_string_literal: true

class Resolvers::Meta::Federations < Resolvers::Base
  type [Types::Meta::Federation], null: false
  description "Get all available federations"

  def resolve(lookahead: nil)
    query = apply_lookaheads(lookahead, Federation.all)
    query.order(name: :asc)
  end
end
