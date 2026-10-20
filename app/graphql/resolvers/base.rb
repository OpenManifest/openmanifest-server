# frozen_string_literal: true

module Resolvers
  class Base < GraphQL::Schema::Resolver
    include Extensions::Resolver::AppSignal
    include Support::OperatorContext
    include Support::Authorization
  end
end
