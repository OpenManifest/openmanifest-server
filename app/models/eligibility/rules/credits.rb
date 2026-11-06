# frozen_string_literal: true

module Eligibility
  module Rules
    # The member can pay for the slot (`require_credits`, unless the operator lets credits go negative)
    class Credits < Rule
      self.bypass_permission = :createUserSlot

      def check(context)
        member = context.membership
        return if member.nil? || context.is_guest? || !(context.create? || context.summary?)

        operator = context.operator
        # A prepaid slot (a tandem's, charged to the guest) takes nothing from the member's wallet
        return not_required("credits") if operator.allow_negative_credits? || !operator.require_credits? || context.slot.prepaid?

        credits = member.credits_cents || 0
        # Without a ticket, the member needs some credits to be going on with
        cost = context.cost_cents || 0
        ok = context.cost_cents ? cost <= credits : credits.positive?
        return pass("credits", amount_cents: credits) if ok

        fail_with("credits", "Not enough credits to manifest for this jump", amount_cents: credits)
      end
    end
  end
end
