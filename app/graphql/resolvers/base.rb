# frozen_string_literal: true

module Resolvers
  class Base < GraphQL::Schema::Resolver
    include Extensions::Resolver::AppSignal
  end
end
