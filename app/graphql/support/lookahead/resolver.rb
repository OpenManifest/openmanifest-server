module Support::Lookahead::Resolver
  extend ActiveSupport::Concern

  included do
    class MissingScope < StandardError; end

    class MissingLookahead < StandardError; end

    # Initializes a query from a lookahead
    # and the given scope
    #
    # @param [GraphQL::Execution::Lookahead] Lookahead object
    # @param [ActiveRecord::Relation] query_scope Optional scope if no scope declared on the resolver
    def apply_lookaheads(lookahead, query_scope = nil)
      current_scope = query_scope || scope
      fail_on_missing_lookahead_scope unless current_scope
      warn "No lookahead block defined for #{self.class.unwrapped_type.name}" unless lookahead_defined?
      self.class.unwrapped_type.apply_lookaheads(
        unwrap_lookahead_connection(lookahead),
        current_scope
      )
    end

    # Checks if the resolvers return type has a lookahead
    # block defined
    def lookahead_defined?
      self.class.unwrapped_type.respond_to?(:apply_lookaheads)
    end

    # Unwrap connections to get the base type with the lookahead
    # block definition
    #
    # @param [GraphQL::Execution::Lookahead] lookahead
    # @return [GraphQL::Execution::Lookahead]
    def unwrap_lookahead_connection(lookahead)
      return lookahead.selection(:edges).selection(:node) if lookahead.selects?(:edges) && lookahead.selection(:edges).selects?(:node)
      lookahead
    end

    def fail_on_missing_lookahead_scope
      raise MissingScope, "No scope defined on #{self.class.name}, pass scope as second argument or declare a scope method"
    end
  end

  class_methods do
    # Unwraps the type of a resolver to get the base node
    # from any array or connection type
    #
    # @return [GraphQL::Schema::Object]
    def unwrap(field_type)
      return unwrap(field_type&.first) if field_type&.is_a?(Array)
      return unwrap(field_type&.of_type) if field_type&.respond_to?(:of_type)
      return unwrap(field_type&.fields['nodes']&.type) if field_type&.ancestors&.include?(Types::Base::Connection)
      field_type
    end

    # Returns the node type of the resolver
    #
    # @return [GraphQL::Schema::Object]
    def unwrapped_type
      unwrap(type)
    end
  end
end
