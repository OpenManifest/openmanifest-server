# frozen_string_literal: true

module Mutations::Setup::Equipment
  # Staff run a member's personal equipment from the office: whoever holds updateUser at a dropzone where the rig's
  # owner is a member may create, update and archive the owner's rigs. Members keep full control of their own rigs.
  module OfficeAccess
    private

    # @param [User, nil] owner the user the rig belongs to
    # @return [Boolean]
    def staff_of_member?(owner)
      return false unless owner

      caller_user = context[:current_resource]
      owner.dropzone_users.kept.pluck(:dropzone_id).any? do |dropzone_id|
        caller_user.can?(:updateUser, dropzone_id: dropzone_id)
      end
    end
  end
end
