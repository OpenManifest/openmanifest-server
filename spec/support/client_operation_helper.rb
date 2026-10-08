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

# Reading `dropzone { currentConditions }` creates a weather record that calls the winds service (BUG-045).
# Stub it so request specs never touch the network.
RSpec.configure do |config|
  config.before(:each, type: :request) do
    altitudes = [0, 1000, 2000, 5000, 7000, 8000, 10_000, 12_000, 14_000].map(&:to_s)
    winds = {
      "speed" => altitudes.index_with { |_| 10 },
      "direction" => altitudes.index_with { |_| 270 },
      "temp" => altitudes.index_with { |_| 15 },
    }
    stub_request(:get, %r{markschulze\.net/winds/winds\.php}).to_return(status: 200, body: winds.to_json)
  end
end
