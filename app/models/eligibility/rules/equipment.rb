# frozen_string_literal: true

module Eligibility
  module Rules
    # The items a slot needs are there, inspected and in service (`require_equipment`, `require_equipment_inspection`,
    # `require_equipment_in_service`). For a member without a slot: their own items of the kinds the operator needs.
    # Chosen with the slot, so only where a person chooses the items (scope `:manifest`).
    class Equipment < Rule
      self.scope = :manifest
      self.bypass_permission = :createUserSlot

      def applies?(operator) = operator.module?(:equipment)

      def check(context)
        return if context.membership.nil? || context.is_guest?
        return check_member(context) if context.summary?
        return unless context.create?

        items = context.equipment
        [present(context, items), inspected(context, items), in_service(context, items)].compact
      end

      private

      def kinds_needed(context)
        context.operator.equipment_kinds.select do |kind|
          kind.required_for?(ticket_type_id: context.ticket_type&.id, activity_type_id: context.activity_type&.id)
        end
      end

      def present(context, items)
        return not_required("equipment") unless context.operator.require_equipment?

        missing = kinds_needed(context).reject { |kind| items.any? { |item| item.kind_id == kind.id || item.kind.key == kind.key } }
        return pass("equipment") if missing.empty?

        fail_with("equipment", "Needs #{missing.map(&:name).to_sentence.downcase} to manifest", problem: "equipment_missing")
      end

      # An item of the member's must carry a current, ok inspection by the operator; the operator's own need none
      def inspected(context, items)
        return not_required("equipment_inspection") unless context.operator.require_equipment_inspection?

        own = items.select { |item| item.user_id.present? }
        uninspected = own.reject { |item| item.inspected_at?(context.operator) }
        return pass("equipment_inspection") if uninspected.empty?

        fail_with("equipment_inspection", "#{uninspected.map { |item| item.name.presence || item.kind.name }.to_sentence} needs an inspection", problem: "equipment_not_inspected")
      end

      def in_service(context, items)
        return not_required("equipment_service") unless context.operator.require_equipment_in_service?

        overdue = items.reject(&:in_service?)
        return pass("equipment_service", expires_at: items.filter_map(&:service_due_at).min) if overdue.empty?

        fail_with("equipment_service", "#{overdue.map { |item| item.name.presence || item.kind.name }.to_sentence} is due for service", problem: "equipment_overdue", expires_at: overdue.filter_map(&:service_due_at).min)
      end

      # What the member's inspections say (read from the member's loaded inspections, so a list of members costs no query for
      # each): an item with a current, ok inspection, and one of them in service
      def check_member(context)
        operator = context.operator
        inspections = context.membership.equipment_inspections.select { |inspection| inspection.is_ok && inspection.current? }
        [member_inspection(operator, inspections), member_service(operator, inspections)]
      end

      def member_inspection(operator, inspections)
        return not_required("equipment_inspection") unless operator.require_equipment_inspection?
        return fail_with("equipment_inspection", "No inspected equipment", problem: "equipment_not_inspected") if inspections.empty?

        expiry = inspections.filter_map { |inspection| inspection.equipment.kind.inspection_expires_at(inspection.updated_at) }
        pass("equipment_inspection", expires_at: expiry.size == inspections.size ? expiry.max : nil)
      end

      def member_service(operator, inspections)
        return not_required("equipment_service") unless operator.require_equipment_in_service?

        serviceable = inspections.filter_map(&:equipment).select(&:in_service?)
        return fail_with("equipment_service", "No equipment in service", problem: "equipment_overdue") if serviceable.empty?

        pass("equipment_service", expires_at: serviceable.filter_map(&:service_due_at).max)
      end
    end
  end
end
