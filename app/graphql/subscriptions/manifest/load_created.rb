class Subscriptions::Manifest::LoadCreated < Types::Base::Subscription
  # `load_id` loads a `load`
  include Support::DropzoneContext
  argument :dropzone_id, ID, required: true
  field :load, Types::Manifest::Load, null: true

  extras [:lookahead]

  def update(dropzone_id:, lookahead: nil)
    query = ::Types::Manifest::Load.apply_lookaheads(
      lookahead,
      ::Load.all
    )
    { load: query.find_by(id: object[:load_id]) }
  end
end
