# frozen_string_literal: true

module Types::Operator
  class CrewRoleScope < Types::Base::Enum
    graphql_name "CrewRoleScope"

    ::CrewRole::SCOPES.each { |scope| value scope, scope }
  end
end
