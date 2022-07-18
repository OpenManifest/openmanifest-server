# frozen_string_literal: true

class Resolvers::Load < Resolvers::Base
  description "Get load by id"
  type Types::LoadType
  argument :id, Int, required: true

  def resolve(
    id: nil,
    lookahead: nil
  )
    query = Load.kept
    query = query.includes(slots: :dropzone_user)      if lookahead.selects?(:slots)
    query = query.includes(:gca)                       if lookahead.selects?(:gca)
    query = query.includes(:load_master)               if lookahead.selects?(:load_master)
    query = query.includes(:pilot)                     if lookahead.selects?(:pilot)
    query = query.includes(:plane)                     if lookahead.selects?(:plane)

    query.find(id)
  end
end
