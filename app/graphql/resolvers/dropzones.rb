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
    lookahead = lookahead.selection(:edges).selection(:node)

    apply_lookaheads(
      lookahead,
      context[:access_context].dropzones
    ).distinct.order(id: :asc)
  end
end
