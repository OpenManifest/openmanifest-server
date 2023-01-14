# frozen_string_literal: true

class Resolvers::Dropzone < Resolvers::Base
  type Types::DropzoneType, null: true
  description "Get dropzone details"
  argument :id, GraphQL::Types::ID, required: true

  def resolve(id:, lookahead: nil)
    query = apply_lookaheads(
      lookahead,
      context[:access_context].dropzones
    )
    query.find_by(id: id)
  end
end
