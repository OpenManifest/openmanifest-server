class Types::Base::Subscription < GraphQL::Schema::Subscription
  # Hook up base classes
  object_class Types::Base::Object
  field_class Types::Base::Field
  argument_class Types::Base::Argument

  def authorized?
    return true if context[:current_resource].present?
    raise GraphQL::ExecutionError, "You must be logged in to subscribe"
  end
end
