# frozen_string_literal: true

class Resolvers::Users::DropzoneUser < Resolvers::Base
  type Types::Users::DropzoneUser, null: true
  description "Get a specific user at a dropzone"

  argument :id, ID, required: true

  def resolve(id: nil, lookahead: nil)
    return nil unless id
    query = apply_lookaheads(lookahead, DropzoneUser.all)

    query.find_by(id: id)
  end
end
