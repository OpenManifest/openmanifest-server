class DailyLog::Update < ApplicationInteraction
  record :operator
  date :date, default: -> { DateTime.current }
  string :notes, default: nil
  record :duty_officer, class: ::Membership, default: nil

  allow updateOperator: 'You are not authorized to update the master log'

  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :debug,
      resource: entry,
      action: :assigned,
      access_level: :admin,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: copy("activity.daily_log.updated", user: access_context.user.name, date: date.iso8601, changes: changes_json),
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
      operator: access_context.operator,
      created_by: access_context.subject,
      message: copy("activity.daily_log.update_failed", user: access_context.user.name, date: date.iso8601, changes: changes_json),
      details: errors.full_messages.join(", ")
    )
  end

  steps :update

  def update
    entry.assign_attributes(
      {
        duty_officer: duty_officer,
        notes: notes,
      }.compact
    )
    errors.merge!(entry.errors) unless entry.save
    entry.store!
    entry.reload
  end

  private

  # What the call changes, for the activity log
  def changes_json
    { duty_officer: duty_officer&.user&.name, notes: notes }.compact.to_json
  end

  def entry
    @entry ||= operator.daily_logs.at(date)
  end
end
