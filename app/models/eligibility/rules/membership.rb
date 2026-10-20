# frozen_string_literal: true

module Eligibility
  module Rules
    # The member's membership has not run out (`require_membership`)
    class Membership < Rule
      self.bypass_permission = :createUserSlot

      def check(context)
        member = context.membership
        return if member.nil? || context.is_guest? || !(context.create? || context.summary?)
        return not_required("membership") unless context.operator.require_membership?

        expires_at = member.expires_at
        # A membership that never began counts as out of date
        return pass("membership", expires_at: expires_at) if (expires_at || 1.second.ago) > Time.current

        fail_with("membership", "#{member.user.name}'s membership has expired", expires_at: expires_at)
      end
    end
  end
end
