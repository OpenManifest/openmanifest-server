# frozen_string_literal: true

class Resolvers::Aircrafts < Resolvers::Base
  type [Types::PlaneType], null: true
  description "Get Aircrafts for a dropzone"
  argument :dropzone_id, Int, required: true

  def resolve(dropzone_id: nil, lookahead: nil)
    query = Plane.kept
    query = query.includes(:dropzone)             if lookahead.selects?(:dropzone)
    query = query.where(dropzone_id: dropzone_id) if dropzone_id
    query.order(name: :asc)
  end
end
