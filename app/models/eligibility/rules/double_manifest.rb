# frozen_string_literal: true

module Eligibility
  module Rules
    # The member is not on another load of the day that has not left (`allow_double_manifesting`)
    class DoubleManifest < Rule
      self.bypass_permission = :createDoubleSlot

      def check(context)
        member = context.membership
        return if member.nil? || context.is_guest? || context.summary? || !context.create?

        operator = context.operator
        return not_required("double_manifest") if operator.allow_double_manifesting?

        # A load that left (or landed) without ever being called is not `active` by its call, but it is not ahead of them either
        waiting = operator.loads.on(operator.today).active.where.not(state: %i(departed completed cancelled))
        other = member.slots.where(load: waiting).where.not(id: context.slot.id)
        return pass("double_manifest") unless other.exists?

        fail_with("double_manifest", "Double-manifesting is not allowed")
      end
    end
  end
end
