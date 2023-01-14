# frozen_string_literal: true

module Types::Base
  class Connection < GraphQL::Types::Relay::BaseConnection
    # add `nodes` and `pageInfo` fields, as well as `edge_type(...)` and `node_nullable(...)` overrides
    include GraphQL::Types::Relay::ConnectionBehaviors
  end
end
