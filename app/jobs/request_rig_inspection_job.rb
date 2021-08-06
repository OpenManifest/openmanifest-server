# frozen_string_literal: true

class RequestRigInspectionJob < ApplicationJob
  queue_as :default

  def perform(rig_id, dropzone_user_id)
    if dz_user = DropzoneUser.find(dropzone_user_id)
      rig = Rig.find(rig_id)

      # Find all users at this dropzone with permissions to perform
      # rig inspections
      dz_user.dropzone.dropzone_users.with_acting_permission(:actAsRigInspector).each do |inspector|
        # Only send once
        unless Notification.where(received_by: inspector, type: :rig_inspection_requested, resource: rig).exists?
          ::Notification.create(
            received_by: inspector,
            message: "#{rig.user.name} needs a rig inspection",
            type: :rig_inspection_requested,
            resource: rig,
            sent_by: dz_user
          )
        end
      end
    end
  rescue
    # TODO: Handle these errors
    # Ignore if notification is removed before sending
  end
end
