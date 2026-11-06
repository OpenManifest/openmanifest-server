class Subscriptions::Manifest::LoadCreated < Types::Base::Subscription
  # `load_id` loads a `load`
  include Support::OperatorContext

  argument :operator_id, ID, required: true
  field :load, Types::Manifest::Load, null: true

  # Only members of the operator hear about its new loads (BUG-011)
  def authorized?(operator_id:, **)
    super
    authorize_operator!(::Operator.find_by(id: operator_id))
    true
  end

  def update(operator_id:)
    query = ::Load.all
    { load: query.find_by(id: object[:load_id]) }
  end
end
