# frozen_string_literal: true

# Asks the equipment inspectors of an operator to inspect a member's equipment, once per inspector and equipment
class RequestEquipmentInspectionJob < ApplicationJob
  queue_as :default

  # The equipment or the member was removed in the meantime
  discard_on ActiveRecord::RecordNotFound

  def perform(equipment_id, membership_id)
    dz_user = Membership.find(membership_id)
    equipment = Equipment.find(equipment_id)

    # Everyone at this operator who may inspect equipment, through their role or granted to them
    inspectors = dz_user.operator.memberships.kept.includes(:user_role, :permissions).select { |member| member.can?(:actAsEquipmentInspector) }
    inspectors.each do |inspector|
      next if Notification.exists?(received_by: inspector, notification_type: :equipment_inspection_requested, resource: equipment)

      Notification.create!(
        received_by: inspector,
        message: "#{equipment.user.name} needs an equipment inspection",
        notification_type: :equipment_inspection_requested,
        resource: equipment,
        sent_by: dz_user
      )
    end
  end
end
