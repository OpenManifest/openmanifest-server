class Subscriptions::Users::UserUpdated < Types::Base::Subscription
  # `dropzone_user_id` loads a `dropzone_user`
  argument :dropzone_user_id, ID, loads: Types::Users::DropzoneUser
  field :dropzoneUser, Types::Users::DropzoneUser, null: true

  # It's passed to other methods as `load`
  def subscribe(dropzone_user:)
    dropzone_user
  end

  def update(dropzone_user:)
    dropzone_user.reload
  end
end
