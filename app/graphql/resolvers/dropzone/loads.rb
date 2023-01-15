# frozen_string_literal: true

class Resolvers::Dropzone::Loads < Resolvers::Base
  type Types::Manifest::Load.connection_type, null: false
  description "Get all loads"

  argument :date, GraphQL::Types::ISO8601Date, required: false,
                                               prepare: -> (value, ctx) { value.to_date },
                                               description: "Search for loads for a specific day"
  argument :dropzone, GraphQL::Types::ID, required: true,
                                          prepare: -> (value, ctx) { ::Dropzone.find_by(id: value) }
  def resolve(dropzone: nil, earliest_timestamp: nil, lookahead: nil, date: nil)
    return nil unless dropzone
    query = apply_lookaheads(lookahead, dropzone.loads)
    Time.use_zone(dropzone.time_zone) do
      query = query.where(loads: { created_at: date.all_day }) unless date.nil?
      query.order(created_at: :desc)
    end
  end
end
