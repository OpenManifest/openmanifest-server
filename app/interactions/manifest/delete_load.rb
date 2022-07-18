# frozen_string_literal: true

class Manifest::DeleteLoad < ApplicationInteraction
  record :load

  allow deleteLoad: "You dont have permissions to delete this load"
  steps :archive_load,
        :load

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      level: :error,
      access_context: access_context,
      access_level: :user,
      resource: load,
      action: :deleted,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} archived load ##{load.load_number}"
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      level: :error,
      access_context: access_context,
      resource: load,
      action: :deleted,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} could not archive load ##{load.load_number}",
      details: errors.full_messages.join(", ")
    )
  end

  def archive_load
    load.discard
  end
end
