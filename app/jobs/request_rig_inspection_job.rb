# frozen_string_literal: true

# Asks the rig inspectors of an operator to inspect a member's rig, once per inspector and rig
class RequestRigInspectionJob < ApplicationJob
  queue_as :default

  # The rig or the member was removed in the meantime
  discard_on ActiveRecord::RecordNotFound

  def perform(rig_id, membership_id)
    dz_user = Membership.find(membership_id)
    rig = Rig.find(rig_id)

    # Everyone at this operator who may inspect rigs, through their role or granted to them
    inspectors = dz_user.operator.memberships.kept.includes(:user_role, :permissions).select { |member| member.can?(:actAsEquipmentInspector) }
    inspectors.each do |inspector|
      next if Notification.exists?(received_by: inspector, notification_type: :rig_inspection_requested, resource: rig)

      Notification.create!(
        received_by: inspector,
        message: "#{rig.user.name} needs a rig inspection",
        notification_type: :rig_inspection_requested,
        resource: rig,
        sent_by: dz_user
      )
    end
  end
end
