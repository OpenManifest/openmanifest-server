# frozen_string_literal: true

module Mutations::Setup::Equipment
  # Staff run a member's personal equipment from the office: whoever holds updateUser at an operator where the rig's
  # owner is a member may create, update and archive the owner's rigs. Members keep full control of their own rigs.
  module OfficeAccess
    private

    # @param [User, nil] owner the user the rig belongs to
    # @return [Boolean]
    def staff_of_member?(owner)
      return false unless owner

      caller_user = context[:current_resource]
      owner.memberships.kept.pluck(:operator_id).any? do |operator_id|
        caller_user.can?(:updateUser, operator_id: operator_id)
      end
    end
  end
end
