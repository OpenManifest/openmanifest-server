# frozen_string_literal: true

module Types::Base
  class Input < GraphQL::Schema::InputObject
    argument_class Types::Base::Argument
  end
end
