class Subscriptions::Users::UserUpdated < Types::Base::Subscription
  argument :membership_id, ID, required: true
  field :membership, Types::Users::Membership, null: true

  # A member follows their own membership; anybody else's needs readUser at that operator (BUG-011)
  def authorized?(membership_id:, **)
    super
    membership = ::Membership.find_by(id: membership_id)
    authorize_record!(membership, membership&.user_id == current_user.id ? nil : :readUser)
    true
  end

  # It's passed to other methods as `load`
  def subscribe(membership_id:)
    query = ::Membership.all
    { membership: query.find_by(id: membership_id) }
  end

  def update(membership_id:)
    query = ::Membership.all
    { membership: query.find_by(id: membership_id) }
  end
end
