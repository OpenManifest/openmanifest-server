# frozen_string_literal: true

class Setup::Operators::UpdateVisibility < ApplicationInteraction
  record :operator
  string :event

  validates_inclusion_of :event, in: Operator.state_machine.events.keys.map(&:to_s)

  steps :check_access,
        :fire_event,
        :operator

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :info,
      access_level: :admin,
      message: "Operator (#{operator.name}) visibility was set to #{operator.state} by #{access_context.user.name}",
      resource: operator,
      action: :created,
      created_by: access_context.subject,
      operator: operator,
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      access_level: :admin,
      message: "#{access_context.user.name} is not allowed to #{event} #{operator.name}",
      resource: access_context.operator,
      action: :created,
      created_by: access_context.subject,
      operator: operator,
    )
  end

  def check_access
    case event.to_sym
    when :request_publication, :unpublish
      errors.add(:base, "You cannot perform this action") unless moderator? || owner?
    when :publish, :archive
      errors.add(:base, "You cannot perform this action") unless moderator?
    end
  end

  def fire_event
    operator.fire_state_event event
    operator.save!
  end

  private

  # Moderators are decided from the acting user: they need not be members of the operator (BUG-089)
  def moderator?
    access_context.user.is_moderator?
  end

  def owner?
    access_context.subject.present? && operator.memberships.owner.include?(access_context.subject)
  end
end
