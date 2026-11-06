# frozen_string_literal: true

class Setup::Equipment::CreateEquipmentInspection < ApplicationInteraction
  allow actAsEquipmentInspector: "You dont have permission to inspect equipment at this operator"
  record :equipment
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
      message: "#{access_context.user.name} inspected #{owner_name}'s #{equipment.make} #{equipment.model} and marked it as #{is_ok ? 'OK' : 'NOT OK'}"
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
      resource: equipment,
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} failed to inspect #{owner_name}'s #{equipment&.make} #{equipment&.model}. It was not marked as #{is_ok ? 'OK' : 'NOT OK'}"
    )
  end

  def build_inspection
    @inspection = EquipmentInspection.find_or_initialize_by(
      equipment: equipment,
      membership: (equipment.user_id && operator.memberships.find_by(user_id: equipment.user_id)) || access_context.subject
    )
    @inspection.form_template = equipment.kind.inspection_form_template
    @inspection.assign_attributes(
      definition: definition,
      is_ok: is_ok,
      inspected_by: access_context.subject
    )
  end

  def save
    errors.merge(@inspection.errors) unless @inspection.save
    # A new inspection of the same item starts its validity again, even when nothing in it changed
    @inspection.touch if @inspection.persisted? && !@inspection.saved_changes?
    @inspection
  end

  private

  def owner_name
    equipment&.user&.name || operator&.name
  end
end
