# frozen_string_literal: true

require "active_interaction"

class Access::GrantPermission < ApplicationInteraction
  record :membership
  record :permission

  steps :can_grant?,
        :grant_permission,
        :membership

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: membership,
      access_level: :user,
      action: :deleted,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} granted permission `#{permission.name}` to #{membership.user.name}"
    )
    Notification.create(
      received_by: membership,
      message: "#{access_context.user.name} gave you access to `#{permission.name}`",
      notification_type: :permission_granted,
      resource: membership,
      sent_by: access_context.subject
    )
  end

  def can_grant?
    errors.add(:base, "You are not authorized to grant permissions") unless access_context.can?(:grantPermission)
  end

  def grant_permission
    membership.user_permissions.find_or_create_by(
      permission: permission
    )
    membership.user_permissions.reload
  end
end
