class Subscriptions::Manifest::LoadUpdated < Types::Base::Subscription
  # `load_id` loads a `load`
  argument :load_id, ID, loads: Types::Manifest::Load
  field :load, Types::Manifest::Load, null: true

  # It's passed to other methods as `load`
  def subscribe(load:)
    load
  end

  def update(room:)
    load.reload
  end
end
