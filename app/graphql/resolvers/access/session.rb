class Resolvers::Access::Session < Resolvers::Base
  type Types::SessionType
  description 'Get the current user session, with or without dropzone'
  argument :dropzone, ID, required: false

  def resolve(dropzone: nil, lookahead: nil)
    Dropzone.includes(
      dropzone_users: [
        :license,
        :user,
        :user_role,
        :permissions,
        :role_permissions
      ]).find_by(id: value)
  end

  def authorized?
    return false unless context[:current_user]
  end
end