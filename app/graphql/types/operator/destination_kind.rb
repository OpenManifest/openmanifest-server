# frozen_string_literal: true

module Types::Operator
  class DestinationKind < Types::Base::Enum
    graphql_name "DestinationKind"

    ::Destination::KINDS.each { |kind| value kind, kind }
  end
end
