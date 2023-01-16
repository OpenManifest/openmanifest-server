class Subscriptions::Manifest::LoadUpdated < Types::Base::Subscription
  # `load_id` loads a `load`
  argument :load_id, ID, as: :load,
                         prepare: -> (value, ctx) { ::Load.find_by(id: value) }
  field :load, Types::Manifest::Load, null: true

  # It's passed to other methods as `load`
  def subscribe(load:)
    { load: load }
  end

  def update(load:)
    super
  end
end
