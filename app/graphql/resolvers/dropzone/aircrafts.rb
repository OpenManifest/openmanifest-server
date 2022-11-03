# frozen_string_literal: true

class Resolvers::Dropzone::Aircrafts < Resolvers::Base
  type [Types::PlaneType], null: true
  description "Get Aircrafts for a dropzone"
  argument :dropzone, GraphQL::Types::ID, required: true,
           prepare: -> (value, ctx) { ::Dropzone.find_by(id: value) }

  def resolve(dropzone: nil, lookahead: nil)
    return nil unless dropzone
    query = dropzone.planes.kept
    query = query.includes(:dropzone)             if lookahead.selects?(:dropzone)
    query.order(name: :asc)
  end
end
