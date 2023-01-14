class Support::Lookahead::Executor
  attr_accessor :lookahead

  # This block is defined on each GraphQL type to declare
  # the lookahead for that class' scope
  # rubocop:disable Style/ClassVars
  @@scope = ->(query) do
    warn "No scope defined for #{self.class.name}"
    query
  end
  # rubocop:enable Style/ClassVars

  # Delegate selects?, selection and selections to the lookahead
  # to make it available in the block
  delegate :selects?, :selection, :selections, to: :lookahead

  # Initialize this class with the lookahead object
  def initialize(lookahead_object)
    self.lookahead = lookahead_object
  end

  # Executes the block in the context of this class,
  # passing the query as the first argument
  #
  # @param [ActiveRecord::Relation] scope
  # @return [ActiveRecord::Relation]
  def on(query)
    instance_exec(query, &@@scope)
  end
end
