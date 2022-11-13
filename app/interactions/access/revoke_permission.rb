# frozen_string_literal: true

require "active_interaction"

class Access::RevokePermission < ApplicationInteraction
  record :dropzone_user
  record :permission

  steps :can_revoke?,
        :revoke_permission,
        :dropzone_user

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: dropzone_user,
      access_level: :user,
      action: :deleted,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} revoked permission `#{permission}` for #{dropzone_user.user.name}"
    )
    Notification.create(
      received_by: dropzone_user,
      message: "#{access_context.subject.user.name} disabled the `#{permission}` permission for you",
      notification_type: :permission_revoked,
      resource: dropzone_user,
      sent_by: access_context.subject
    )
  end

  def can_revoke?
    errors.add(:base, "You are not authorized to revoke permissions") unless access_context.can?(:revokePermission)
  end

  def revoke_permission
    dropzone_user.user_permissions.where(
      permission: permission
    ).destroy_all
    dropzone_user.user_permissions.reload
    dropzone_user.reload
  end
end
