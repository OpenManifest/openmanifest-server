# frozen_string_literal: true

module Types
  module Input
    class CrewRoleInput < Types::Base::Input
      argument :operator_id, Int, required: false
      argument :key, String, required: false
      argument :name, String, required: false
      argument :scope, Types::Operator::CrewRoleScope, required: false
      argument :required, Boolean, required: false
      argument :occupies_slot, Boolean, required: false
      argument :permission, String, required: false
      argument :vehicle_kinds, [String], required: false
      argument :position, Int, required: false
    end
  end
end
