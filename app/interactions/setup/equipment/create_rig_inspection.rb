# frozen_string_literal: true

class Setup::Equipment::CreateRigInspection < ApplicationInteraction
  allow actAsRigInspector: "You dont have permission to inspect rigs at this operator"
  record :rig
  record :operator
  string :definition
  boolean :is_ok

  steps :build_inspection,
        :save
  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      access_level: :user,
      resource: @inspection,
      action: :created,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} inspected #{rig.user.name}'s #{rig.make} #{rig.model} and marked it as #{is_ok ? 'OK' : 'NOT OK'}"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      access_level: :admin,
      action: :created,
      resource: rig,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} failed to inspect #{rig&.user&.name}'s #{rig&.make} #{rig&.model}. It was not marked as #{is_ok ? 'OK' : 'NOT OK'}"
    )
  end

  def build_inspection
    @inspection = RigInspection.find_or_initialize_by(
      rig: rig,
      membership: operator.memberships.find_by(
        user_id: rig.user.id
      )
    )
    @inspection.form_template = operator.rig_inspection_template
    @inspection.assign_attributes(
      definition: definition,
      is_ok: is_ok,
      inspected_by: access_context.subject
    )
  end

  def save
    errors.merge(@inspection.errors) unless @inspection.save
    @inspection
  end
end
