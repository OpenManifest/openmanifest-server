# frozen_string_literal: true

module Types::Base
  class Connection < GraphQL::Types::Relay::BaseConnection
    include GraphQL::Types::Relay::ConnectionBehaviors
  end
end
