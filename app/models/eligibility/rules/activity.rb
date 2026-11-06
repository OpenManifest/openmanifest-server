# frozen_string_literal: true

module Eligibility
  module Rules
    # The member's certification level permits the activity (skydiving: the jump type)
    class Activity < Rule
      self.bypass_permission = :createUserSlot

      def applies?(operator) = operator.module?(:activities)

      def check(context)
        activity = context.activity_type
        return if activity.nil? || context.membership.nil?
        return unless context.create?
        # A tandem passenger flies without a licence
        return if context.is_guest? && context.ticket_type&.requires_escort?
        return not_required("activity") unless context.operator.require_certification?
        return pass("activity") if activity.allowed_for?(context.membership)

        fail_with("activity", "User cannot be manifested for #{activity.name} jumps", field: :activity_type)
      end
    end
  end
end
