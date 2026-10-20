# frozen_string_literal: true

module Mutations::Setup::CrewRoles
  class UpdateCrewRole < CrewRoleMutation
    argument :attributes, Types::Input::CrewRoleInput, required: true
    argument :id, Int, required: true

    def resolve(attributes:, id:)
      crew_role = ::CrewRole.kept.find(id)
      crew_role.update(attributes.to_h.except(:operator_id)) ? saved(crew_role) : refused(crew_role)
    rescue ActiveRecord::RecordNotFound => error
      { crew_role: nil, field_errors: nil, errors: [error.message] }
    end

    def authorized?(id: nil, attributes: nil)
      permitted?(::CrewRole.find(id).operator_id, "You don't have permissions to update crew roles")
    end
  end
end
