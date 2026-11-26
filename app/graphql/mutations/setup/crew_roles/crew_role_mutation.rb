# frozen_string_literal: true

module Mutations::Setup::CrewRoles
  # What createCrewRole, updateCrewRole and archiveCrewRole share (the permission is updateOperator, like the rest of the
  # operator's setup)
  class CrewRoleMutation < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :crew_role, Types::Operator::CrewRole, null: true

    private

    def saved(crew_role)
      { crew_role: crew_role, errors: nil, field_errors: nil }
    end

    def refused(crew_role)
      {
        crew_role: nil,
        field_errors: crew_role.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: crew_role.errors.full_messages,
      }
    end

    def permitted?(operator_id, message)
      return true if context[:current_resource].can?("updateOperator", operator_id: operator_id)

      [false, { errors: [message] }]
    end
  end
end
