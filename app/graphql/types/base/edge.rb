# frozen_string_literal: true

module Types::Base
  class Edge < GraphQL::Types::Relay::BaseEdge
    # add `node` and `cursor` fields, as well as `node_type(...)` override
    include GraphQL::Types::Relay::EdgeBehaviors
  end
end
