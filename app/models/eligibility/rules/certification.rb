# frozen_string_literal: true

module Eligibility
  module Rules
    # What the ticket and its add-ons ask of the member: a rank of certification level and qualifications. Without a ticket
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
          unmet << :qualification unless member.user.qualified_for?(extra.required_qualification)
        end
        return pass("certification") if unmet.empty?

        fail_with("certification", "#{member.user.name} is missing a certification: #{unmet.uniq.map { |kind| kind.to_s.humanize.downcase }.join(', ')}")
      end

      private

      def check_member(context, member)
        return not_required("certification") unless context.operator.require_certification?
        return pass("certification") if member.certification_level_id.present?

        fail_with("certification", "#{member.user.name} has no certification level", problem: "certification_level_missing")
      end
    end
  end
end
