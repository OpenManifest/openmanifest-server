module Support::OperatorContext
  extend ActiveSupport::Concern

  class_methods do
    # Sets up an Operator argument for a mutation
    # or resolver, which will automatically resolve
    # the operator, and set the operator as the current
    # operator in the access context
    #
    # @return [GraphQL::Schema::Argument]
    def operator(symbol, **opts)
      argument symbol, GraphQL::Types::ID, **opts, prepare: -> (value, ctx) {
        # Anonymous callers have no access context: the authentication check answers them
        ctx[:access_context]&.at_operator(value)&.operator
      }
    end
  end
end
