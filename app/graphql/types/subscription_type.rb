class Types::SubscriptionType < GraphQL::Schema::Object
  field :load_updated, subscription: Subscriptions::Manifest::LoadUpdated
  field :user_updated, subscription: Subscriptions::Users::UserUpdated
end
