# frozen_string_literal: true

module Eligibility
  module Rules
    # What the ticket, its add-ons and the places it goes ask of the member: a rank of certification level and
    # qualifications (a 30 m dive site asks for an advanced rank, nitrox for the nitrox qualification). Without a ticket
    # (a checklist), that the member has a certification level at all (`require_certification`).
    class Certification < Rule
      self.bypass_permission = :createUserSlot

      def applies?(operator) = operator.module?(:certifications)

      def check(context)
        member = context.membership
        return if member.nil? || context.is_guest?
        return check_member(context, member) if context.summary?
        return unless context.create? && context.ticket_type

        unmet = context.ticket_type.unmet_certification_requirements(member)
        context.extras.each do |extra|
          unmet << :qualification unless member.user.qualified_for?(extra.required_qualification, body_ids: context.operator.certification_body_ids)
        end
        too_deep = destinations(context).select { |place| place.min_certification_rank && member.certification_rank < place.min_certification_rank }
        return pass("certification") if unmet.empty? && too_deep.empty?

        message = "#{member.user.name} is missing a certification"
        message += ": #{unmet.uniq.map { |kind| kind.to_s.humanize.downcase }.join(', ')}" if unmet.any?
        message += " for #{too_deep.map(&:name).to_sentence}" if too_deep.any?
        fail_with("certification", message, problem: too_deep.any? && unmet.empty? ? "destination_rank" : "certification")
      end

      private

      # Where the slot goes: its own destination (per slot) and the load's (per load)
      def destinations(context)
        [context.slot.destination, *context.load&.destinations].compact.uniq
      end

      def check_member(context, member)
        return not_required("certification") unless context.operator.require_certification?
        return pass("certification") if member.certification_level_id.present?

        fail_with("certification", "#{member.user.name} has no certification level", problem: "certification_level_missing")
      end
    end
  end
end
