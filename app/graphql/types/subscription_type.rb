class Types::SubscriptionType < Types::Base::Object
  field :load_updated, subscription: Subscriptions::Manifest::LoadUpdated, broadcastable: true
  field :user_updated, subscription: Subscriptions::Users::UserUpdated
end
