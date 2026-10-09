# frozen_string_literal: true

class Resolvers::Dropzones < Resolvers::Base
  type Types::DropzoneType.connection_type, null: false
  description "Get all available dropzones"

  argument :state, [Types::Dropzone::State], required: false,
                                             default_value: nil
  def resolve(
    state: nil,
    lookahead: nil
  )
    query = context[:access_context].dropzones
    query = query.where(state: state.map(&:to_s)) if state.present?

    apply_lookaheads(lookahead, query).distinct.order(id: :asc)
  end
end
