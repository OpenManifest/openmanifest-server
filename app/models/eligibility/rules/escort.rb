# frozen_string_literal: true

module Eligibility
  module Rules
    # An escort takes the guests its ticket allows, and holds the qualification and role the ticket asks for
    class Escort < Rule
      self.bypass_permission = :createUserSlot

      def applies?(operator) = operator.module?(:escorts)

      # Too many guests is no bypass; an unqualified escort is
      def bypassable?(result) = result.problem == "escort_unqualified"

      def check(context)
        return unless context.create?

        guest_slots = context.guest_slots
        return if guest_slots.empty? || context.membership.nil?

        ticket = context.ticket_type
        return fail_with("escort", "#{ticket&.name || 'This ticket'} does not take guests", problem: "no_guests_allowed") unless ticket&.requires_escort?

        if guest_slots.size > ticket.escort_capacity
          capacity = ticket.escort_capacity
          return fail_with("escort", "#{ticket.name} takes at most #{capacity} #{'guest'.pluralize(capacity)} for each escort", problem: "escort_capacity")
        end

        unmet = ticket.unmet_escort_requirements(context.membership)
        return pass("escort") if unmet.empty?

        names = unmet.map { |kind| kind.to_s.humanize.downcase }.join(", ")
        fail_with("escort", "#{context.membership.user.name} cannot escort guests: missing #{names}", problem: "escort_unqualified")
      end
    end
  end
end
