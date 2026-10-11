# frozen_string_literal: true

class Resolvers::Users::DropzoneUser < Resolvers::Base
  type Types::Users::DropzoneUser, null: true
  description "Get a specific user at a dropzone"

  argument :id, ID, required: true

  def resolve(id: nil, lookahead: nil)
    return nil unless id
    query = apply_lookaheads(lookahead, DropzoneUser.all)

    dropzone_user = query.find_by(id: id)
    return nil unless dropzone_user

    # Your own membership is always readable; other members need readUser at their dropzone
    own = current_user && dropzone_user.user_id == current_user.id
    authorize_record!(dropzone_user, own ? nil : :readUser)
    dropzone_user
  end
end
