# frozen_string_literal: true

class Resolvers::Meta::Licenses < Resolvers::Base
  description "Get all licenses for a federation"
  type [Types::Meta::License], null: false
  argument :federation_id, Int, required: false

  def resolve(federation_id: nil, lookahead: nil)
    query = apply_lookaheads(lookahead, License.all)
    query = query.where(federation_id: federation_id) if federation_id

    query.order(name: :asc)
  end
end
