module GraphqlClient
  extend ActiveSupport::Concern

  class_methods do
    def graphql_request(query, variables: {}, headers: {})
      post "/graphql", params: { query: query }
    end

    # Creates a query block to use in specs, e.g:
    # create_query(:first_arg, :second_arg) do
    #   "query { myQuery(firstArg: #{first_arg}, secondArg: #{second_arg}) }"
    # end
    #
    # This creates a method to use for executing the query:
    #
    # execute_query(first_arg: "foo", second_arg: "bar")
    def create_query(*argument_symbols, &block)
      define_method(:execute_query) do |kwargs|
        # Extract each keyword argument to a variable
        argument_symbols.each do |variable|
          define_singleton_method(variable) { kwargs[variable] }
        end

        query = instance_eval(&block)

        post "/graphql",
             params: { query: query },
             headers: user.create_new_auth_token
        json = JSON.parse(response.body, symbolize_names: true)
        puts json if ENV['RSPEC_DEBUG'].present?
        json[:data]
      end
    end
  end
end
