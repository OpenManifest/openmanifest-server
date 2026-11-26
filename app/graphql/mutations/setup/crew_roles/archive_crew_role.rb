# frozen_string_literal: true

module Mutations::Setup::CrewRoles
  # Archives rather than deletes: past loads keep who filled the role
  class ArchiveCrewRole < CrewRoleMutation
    argument :id, Int, required: true

    def resolve(id:)
      crew_role = ::CrewRole.kept.find(id)
      crew_role.discard ? saved(crew_role.reload) : refused(crew_role)
    rescue ActiveRecord::RecordNotFound => error
      { crew_role: nil, field_errors: nil, errors: [error.message] }
    end

    def authorized?(id: nil)
      permitted?(::CrewRole.find(id).operator_id, "You don't have permissions to archive crew roles")
    end
  end
end
