class Subscriptions::Manifest::LoadCreated < Types::Base::Subscription
  # `load_id` loads a `load`
  include Support::DropzoneContext

  argument :dropzone_id, ID, required: true
  field :load, Types::Manifest::Load, null: true

  # Only members of the dropzone hear about its new loads (BUG-011)
  def authorized?(dropzone_id:, **)
    super
    authorize_dropzone!(::Dropzone.find_by(id: dropzone_id))
    true
  end

  def update(dropzone_id:)
    query = ::Load.all
    { load: query.find_by(id: object[:load_id]) }
  end
end
