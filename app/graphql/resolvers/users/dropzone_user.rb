# frozen_string_literal: true

class Resolvers::Users::DropzoneUser < Resolvers::Base
  type Types::DropzoneUserType, null: true
  description "Get a specific user at a dropzone"

  argument :id, ID, required: true

  def resolve(id: nil, lookahead: nil)
    return nil unless id
    query = DropzoneUser
    query = query.includes(:dropzone)   if lookahead.selects?(:dropzone)
    query = query.includes(:jump_types) if lookahead.selects?(:jump_type)
    query = query.includes(:slots)      if lookahead.selects?(:slots)
    query = query.includes(:user)       if lookahead.selects?(:user)
    query = query.includes(:license)    if lookahead.selects?(:license)
    query.find_by(id: id)
  end
end
