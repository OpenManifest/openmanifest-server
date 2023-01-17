class Subscriptions::Users::UserUpdated < Types::Base::Subscription
  argument :dropzone_user_id, ID, required: true
  field :dropzone_user, Types::Users::DropzoneUser, null: true

  extras [:lookahead]

  # It's passed to other methods as `load`
  def subscribe(dropzone_user_id:, lookahead: nil)
    query = ::Types::Users::DropzoneUser.apply_lookaheads(
      lookahead,
      ::DropzoneUser.all
    )
    { dropzone_user: query.find_by(id: dropzone_user_id) }
  end

  def update(dropzone_user_id:, lookahead: nil)
    query = ::Types::Users::DropzoneUser.apply_lookaheads(
      lookahead,
      ::DropzoneUser.all
    )
    { dropzone_user: query.find_by(id: dropzone_user_id) }
  end
end
