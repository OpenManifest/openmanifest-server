# frozen_string_literal: true

class Resolvers::Dropzone::Loads < Resolvers::Base
  type Types::LoadType.connection_type, null: false
  description "Get all loads"

  argument :dropzone, GraphQL::Types::ID, required: true,
           prepare: -> (value, ctx) { Dropzone.find_by(id: value) }
  argument :date, GraphQL::Types::ISO8601Date, required: false,
           prepare: -> (value, ctx) { value.to_date },
           description: "Search for loads for a specific day"
  def resolve(dropzone: nil, earliest_timestamp: nil, lookahead: nil, date: nil)
    return nil unless dropzone
    lookahead = lookahead.selection(:edges).selection(:node)
    query = dropzone.loads
    query = query.includes(slots: :dropzone_user)      if lookahead.selects?(:slots)
    query = query.includes(:gca)                       if lookahead.selects?(:gca)
    query = query.includes(:load_master)               if lookahead.selects?(:load_master)
    query = query.includes(:pilot)                     if lookahead.selects?(:pilot)
    query = query.includes(:plane)                     if lookahead.selects?(:plane)
    query = query.where(loads: { created_at: date.beginning_of_day..date.end_of_day }) unless date.nil?
    query.order(created_at: :desc)
  end
end
