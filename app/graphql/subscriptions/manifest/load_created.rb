class Subscriptions::Manifest::LoadCreated < Types::Base::Subscription
  # `load_id` loads a `load`
  include Support::DropzoneContext
  dropzone :dropzone_id, as: :dropzone, required: true
  field :load, Types::Manifest::Load, null: true

  # It's passed to other methods as `load`
  def subscribe(dropzone:)
    { load: nil }
  end

  def update(load:)
    { load: nil }
  end
end
