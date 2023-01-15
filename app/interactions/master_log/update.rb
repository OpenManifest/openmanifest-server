class MasterLog::Update < ApplicationInteraction
  record :dropzone
  date :date, default: -> { DateTime.current }
  string :notes, default: nil
  record :dzso, class: ::DropzoneUser, default: nil

  allow updateDropzone: 'You are not authorized to update the master log'

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :debug,
      resource: entry,
      action: :assigned,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} updated master log #{date.iso8601} with #{{ dzso: dzso&.user&.name, notes: notes }.compact.to_json}",
    )
  end

  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: entry,
      action: :assigned,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} failed to update master log #{date.iso8601} with #{{ dzso: dzso&.user&.name, notes: notes }.compact.to_json}",
      details: errors.full_messages.join(", ")
    )
  end

  steps :update

  def update
    entry.assign_attributes(
      {
        dzso: dzso,
        notes: notes,
      }.compact
    )
    errors.merge!(entry.errors) unless entry.save
    entry.store!
    entry.reload
  end

  private

  def entry
    @entry ||= dropzone.master_logs.at(date)
  end
end
