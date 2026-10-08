# frozen_string_literal: true

# Executes a named client GraphQL document against the app, as the client would.
module ClientOperationHelper
  def client_operation(name, variables: {}, as: nil)
    headers = as ? as.create_new_auth_token : {}
    post "/graphql",
         params: { query: ClientOperations.document(name), variables: variables.to_json, operationName: name },
         headers: headers
    JSON.parse(response.body).with_indifferent_access
  end
end

RSpec.configure { |config| config.include ClientOperationHelper, type: :request }
