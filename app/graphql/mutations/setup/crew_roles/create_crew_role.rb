# frozen_string_literal: true

module Mutations::Setup::CrewRoles
  class CreateCrewRole < CrewRoleMutation
    argument :attributes, Types::Input::CrewRoleInput, required: true

    def resolve(attributes:)
      crew_role = ::Operator.find(attributes[:operator_id]).crew_roles.new(attributes.to_h.except(:operator_id))
      crew_role.save ? saved(crew_role) : refused(crew_role)
    rescue ActiveRecord::RecordNotFound => error
      { crew_role: nil, field_errors: nil, errors: [error.message] }
    end

    def authorized?(attributes: nil)
      permitted?(attributes[:operator_id], "You don't have permissions to create crew roles")
    end
  end
end
