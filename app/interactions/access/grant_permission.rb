# frozen_string_literal: true

require "active_interaction"

class Access::GrantPermission < ApplicationInteraction
  record :dropzone_user
  record :permission

  steps :can_grant?,
        :grant_permission,
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
      message: "#{access_context.subject.user.name} granted permission `#{permission.name}` to #{dropzone_user.user.name}"
    )
    Notification.create(
      received_by: dropzone_user,
      message: "#{access_context.subject.user.name} gave you access to `#{permission.name}`",
      notification_type: :permission_granted,
      resource: dropzone_user,
      sent_by: access_context.subject
    )
  end

  def can_grant?
    errors.add(:base, 'You are not authorized to grant permissions') unless access_context.can?(:grantPermission)
  end

  def grant_permission
    dropzone_user.user_permissions.find_or_create_by(
      permission: permission
    )
    dropzone_user.user_permissions.reload
  end

end
