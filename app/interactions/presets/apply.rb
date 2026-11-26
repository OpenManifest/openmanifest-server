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
        :create_equipment_kinds

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

  TICKET_ATTRIBUTES = %w(
    cost_cents allow_manifesting_self requires_escort escort_capacity currency min_certification_rank participant_limits
    group_limits
  ).freeze

  # A ticket type names its default destination (`destination:`), one of the destinations above; the qualification a
  # member (`requires_qualification:`) or an escort (`escort_qualification:`) needs, by slug; the crew role an escort
  # holds (`escort_crew_role:`), by key
  def create_ticket_types
    presets.fetch("ticket_types", []).each do |attrs|
      ticket = operator.ticket_types.find_or_initialize_by(name: attrs.fetch("name"))
      next if ticket.persisted?

      ticket.assign_attributes(attrs.slice(*TICKET_ATTRIBUTES))
      ticket.default_destination = operator.destinations.find_by!(name: attrs["destination"]) if attrs["destination"]
      ticket.required_qualification = qualification(attrs["requires_qualification"])
      ticket.escort_qualification = qualification(attrs["escort_qualification"])
      ticket.escort_crew_role = operator.crew_roles.kept.find_by!(key: attrs["escort_crew_role"]) if attrs["escort_crew_role"]
      ticket.save!
    end
  end

  def create_extras
    presets.fetch("extras", []).each do |attrs|
      extra = operator.extras.find_or_initialize_by(name: attrs.fetch("name"))
      next if extra.persisted?

      extra.assign_attributes(attrs.slice("cost_cents"))
      extra.required_qualification = qualification(attrs["requires_qualification"])
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

  # The kinds of equipment the template keeps track of, each with the inspection form its `inspection_form:` names
  def create_equipment_kinds
    ::EquipmentKind.create_presets!(operator, created_by: created_by)
  end

  private

  def template = operator.industry_template

  def presets = template.presets

  # The qualification of this slug at the first body the operator accepts that issues it. Holders of the same
  # qualification at another accepted body meet it too (User#qualified_for? compares slugs). None when no accepted body
  # issues it: the owner sets it after accepting one.
  def qualification(slug)
    return nil if slug.blank?

    ::Qualification.where(slug: slug, certification_body_id: operator.certification_body_ids).order(:certification_body_id, :id).first
  end
end
