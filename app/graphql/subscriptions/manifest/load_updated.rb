class Subscriptions::Manifest::LoadUpdated < Types::Base::Subscription
  argument :load_id, ID, required: true
  field :load, Types::Manifest::Load, null: true

  extras [:lookahead]

  # Only members of the load's dropzone may follow it (BUG-011)
  def authorized?(load_id:, **)
    super
    authorize_record!(::Load.find_by(id: load_id))
    true
  end

  def subscribe(load_id:, lookahead: nil)
    query = ::Types::Manifest::Load.apply_lookaheads(
      lookahead,
      ::Load.all
    )
    { load: query.find_by(id: load_id) }
  end

  def update(load_id:, lookahead: nil)
    query = ::Types::Manifest::Load.apply_lookaheads(
      lookahead,
      ::Load.all
    )
    { load: query.find_by(id: load_id) }
  end
end
