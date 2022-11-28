class Resolvers::Access::Session < Resolvers::Base
  type Types::Access::SessionType, null: true
  description 'Get the current user session, with or without dropzone'
  argument :dropzone, ID, required: false

  def resolve(dropzone: nil, lookahead: nil)
    Dropzone.includes(
      :user_roles,
      dropzone_users: [
        :license,
        :user,
        :user_role,
        :permissions,
        :role_permissions,
      ]
    ).find_by(id: dropzone)
  end

  def authorized?
    return false unless context[:current_user]
  end
end
