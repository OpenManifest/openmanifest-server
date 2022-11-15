# frozen_string_literal: true

class Setup::Dropzones::UpdateVisibility < ApplicationInteraction
  record :dropzone
  string :event

  validates_inclusion_of :event, in: Dropzone.state_machine.events.keys.map(&:to_s)

  steps :check_access,
        :fire_event,
        :dropzone

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :info,
      access_level: :admin,
      message: "Dropzone (#{dropzone.name}) visibility was set to #{dropzone.state} by #{@access_context.subject.user.name}",
      resource: dropzone,
      action: :created,
      created_by: access_context.subject,
      dropzone: dropzone,
    )
  end

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      access_level: :admin,
      message: "#{access_context.subject.user.name} is not allowed to #{event} #{dropzone.name}",
      resource: access_context.dropzone,
      action: :created,
      created_by: access_context.subject,
      dropzone: dropzone,
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
    dropzone.fire_state_event event
    dropzone.save!
  end

  private

  def moderator?
    access_context.subject.user.is_moderator?
  end

  def owner?
    dropzone.dropzone_users.owner.include?(access_context.subject)
  end
end
