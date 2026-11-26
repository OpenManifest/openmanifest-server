# frozen_string_literal: true

require "active_interaction"

class Access::RevokePermission < ApplicationInteraction
  record :membership
  record :permission

  steps :can_revoke?,
        :revoke_permission,
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
      message: "#{access_context.user.name} revoked permission `#{permission}` for #{membership.user.name}"
    )
    Notification.create(
      received_by: membership,
      message: "#{access_context.user.name} disabled the `#{permission}` permission for you",
      notification_type: :permission_revoked,
      resource: membership,
      sent_by: access_context.subject
    )
  end

  def can_revoke?
    errors.add(:base, "You are not authorized to revoke permissions") unless access_context.can?(:revokePermission)
  end

  def revoke_permission
    membership.user_permissions.where(
      permission: permission
    ).destroy_all
    membership.user_permissions.reload
    membership.reload
  end
end
