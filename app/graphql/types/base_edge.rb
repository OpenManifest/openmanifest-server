# frozen_string_literal: true

module Types
  class BaseEdge < GraphQL::Types::Relay::BaseEdge
    # add `node` and `cursor` fields, as well as `node_type(...)` override
    include GraphQL::Types::Relay::EdgeBehaviors
  end
end
