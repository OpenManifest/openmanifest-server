# frozen_string_literal: true

class Resolvers::Loads < Resolvers::Base
  type Types::LoadType.connection_type, null: false
  description "Get all loads"

  argument :dropzone, Int, required: true,
           prepare: -> (value, ctx) { Dropzone.find(value) }
  argument :earliest_timestamp, GraphQL::Types::ISO8601DateTime, required: false,
           prepare: -> (value, ctx) { value.to_datetime }
  def resolve(dropzone: nil, earliest_timestamp: nil, lookahead: nil)
    query = dropzone.loads
    query = query.includes(slots: :dropzone_user)      if lookahead.selects?(:slots)
    query = query.includes(:gca)                       if lookahead.selects?(:gca)
    query = query.includes(:load_master)               if lookahead.selects?(:load_master)
    query = query.includes(:pilot)                     if lookahead.selects?(:pilot)
    query = query.includes(:plane)                     if lookahead.selects?(:plane)
    query = query.where("loads.created_at > ?", earliest_timestamp) unless earliest_timestamp.nil?
    query.order(created_at: :desc)
  end
end
