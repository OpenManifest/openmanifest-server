class MasterLog::Update < ApplicationInteraction
  record :operator
  date :date, default: -> { DateTime.current }
  string :notes, default: nil
  record :dzso, class: ::Membership, default: nil

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
      message: "#{access_context.user.name} updated master log #{date.iso8601} with #{{ dzso: dzso&.user&.name, notes: notes }.compact.to_json}",
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
      message: "#{access_context.user.name} failed to update master log #{date.iso8601} with #{{ dzso: dzso&.user&.name, notes: notes }.compact.to_json}",
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
    @entry ||= operator.master_logs.at(date)
  end
end
