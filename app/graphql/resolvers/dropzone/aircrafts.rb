# frozen_string_literal: true

class Resolvers::Dropzone::Aircrafts < Resolvers::Base
  type [Types::Dropzone::Aircraft], null: true
  description "Get Aircrafts for a dropzone"
  dropzone :dropzone, required: true

  def resolve(dropzone: nil, lookahead: nil)
    return nil unless dropzone
    query = apply_lookaheads(lookahead, dropzone.planes.kept)

    query.order(name: :asc)
  end
end
