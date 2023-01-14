# frozen_string_literal: true

class Resolvers::Dropzone::Load < Resolvers::Base
  description "Get load by id"
  type Types::Manifest::Load, null: true
  argument :id, GraphQL::Types::ID, required: true

  def resolve(
    id: nil,
    lookahead: nil
  )
    apply_lookaheads(lookahead, Load.kept).find_by(id: id)
  end
end
