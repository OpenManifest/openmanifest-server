# frozen_string_literal: true

# Copies the presets of an operator's industry template into the operator's own tables, once (GENERALISATION §2):
# roles and permissions (with the default roles), vehicle kinds, crew roles, destinations, ticket types, extras, enabled activity types and
# inspection forms. The operator owns the copies afterwards; running it again only adds what is missing. Each later
# Phase 7 task extends it for its own records.
class Presets::Apply < ApplicationInteraction
  record :operator
  object :created_by, class: Membership, default: nil

  steps :copy_settings,
        :create_roles,
        :create_crew_roles,
        :create_destinations,
        :create_ticket_types,
        :create_extras,
        :enable_activity_types,
        :create_inspection_forms

  def copy_settings
    kinds = template.vehicle_kinds
    return if kinds.blank? || operator.settings["vehicle_kinds"].present?

    operator.update!(settings: { vehicle_kinds: kinds })
  end

  def create_roles
    compose(::Setup::Operators::Access::CreateDefaults, operator: operator)
  end

  def create_crew_roles
    ::CrewRole.create_presets!(operator)
  end

  def create_destinations
    presets.fetch("destinations", []).each do |attrs|
      destination = operator.destinations.find_or_initialize_by(name: attrs.fetch("name"))
      next if destination.persisted?

      destination.assign_attributes(attrs.slice("kind", "altitude_m", "location", "stops", "min_certification_rank"))
      destination.save!
    end
  end

  # A ticket type names its default destination (`destination:`), one of the destinations above
  def create_ticket_types
    presets.fetch("ticket_types", []).each do |attrs|
      ticket = operator.ticket_types.find_or_initialize_by(name: attrs.fetch("name"))
      next if ticket.persisted?

      ticket.assign_attributes(attrs.slice("cost_cents", "allow_manifesting_self", "is_tandem", "currency"))
      ticket.default_destination = operator.destinations.find_by!(name: attrs["destination"]) if attrs["destination"]
      ticket.save!
    end
  end

  def create_extras
    presets.fetch("extras", []).each do |attrs|
      extra = operator.extras.find_or_initialize_by(name: attrs.fetch("name"))
      next if extra.persisted?

      extra.assign_attributes(attrs.slice("cost_cents"))
      extra.save!
    end
  end

  def enable_activity_types
    slugs = presets.fetch("activity_types", [])
    return if slugs.empty?

    ::ActivityType.where(slug: slugs).find_each do |activity_type|
      operator.operator_activity_types.find_or_create_by!(activity_type: activity_type)
    end
  end

  def create_inspection_forms
    definition = presets.dig("inspection_forms", "equipment_inspection")
    return if definition.blank? || operator.rig_inspection_template.present?

    template_record = ::FormTemplate.create!(
      name: "Rig Inspection",
      definition: definition.to_json,
      operator: operator,
      created_by: created_by,
      updated_by: created_by
    )
    operator.update!(rig_inspection_template: template_record)
  end

  private

  def template = operator.industry_template

  def presets = template.presets
end
