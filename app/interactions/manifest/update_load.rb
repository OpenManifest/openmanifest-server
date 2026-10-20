# frozen_string_literal: true

require "active_interaction"

class Manifest::UpdateLoad < ApplicationInteraction
  allow :updateLoad

  # Arguments
  record :load
  date_time :dispatch_at, default: nil
  string :name, default: nil
  integer :max_slots, default: nil
  object :gca, class: Membership, default: nil
  object :load_master, class: Membership, default: nil
  object :pilot, class: Membership, default: nil
  object :vehicle, class: Vehicle, default: nil
  # The vehicles of the load with their roles; given, they replace the load's (operators with several vehicles per load)
  array :vehicles, default: nil do
    hash do
      record :vehicle
      string :role, default: "carrying"
    end
  end
  string :state, default: nil
  # The places the load visits, in order; given, they replace the load's (operators with per-load destinations)
  array :destination_ids, default: nil do
    integer
  end
  # The whole crew of the load by role (and by vehicle, for roles per vehicle); given, it replaces the load's
  array :crew, default: nil do
    hash do
      record :crew_role
      record :membership
      record :load_vehicle, default: nil
      record :vehicle, default: nil
    end
  end
  # The version of the load the client based its change on (optimistic locking, BUG-024)
  integer :lock_version, default: nil

  validates_inclusion_of :state, in: Load.states.keys, allow_nil: true

  # The state the client asks for, and the event of the load's state machine that gets it there
  STATE_EVENTS = {
    "open" => :reopen,
    "boarding" => :call,
    "departed" => :depart,
  }.freeze

  steps :check_max_slots,
        :check_vehicle_change,
        :update_load,
        :save,
        :change_state,
        :load

  success do
    if dispatch_at
      time_left = (dispatch_at.to_i - DateTime.now.to_i) / 60
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        operator: access_context.operator,
        created_by: access_context.subject,
        message: "#{access_context.user.name} dispatched load ##{load.load_number} (#{time_left} minute call)"
      )
    elsif inputs.given?(:dispatch_at)
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        operator: access_context.operator,
        created_by: access_context.subject,
        message: "#{access_context.user.name} cancelled call for load ##{load.load_number}"
      )
    end

    if vehicle || vehicles
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        operator: access_context.operator,
        created_by: access_context.subject,
        message: "#{access_context.user.name} changed the #{vehicles ? 'vehicles' : 'vehicle'} for load ##{load.load_number} to #{vehicle_names}"
      )
    end

    if gca
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        operator: access_context.operator,
        created_by: access_context.subject,
        message: "#{access_context.user.name} changed the GCA for load ##{load.load_number} to #{gca.user.name}"
      )
    end

    if load_master
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        operator: access_context.operator,
        created_by: access_context.subject,
        message: "#{access_context.user.name} changed the load master for load ##{load.load_number} to #{load_master.user.name}"
      )
    end
  end

  def check_max_slots
    return if max_slots.blank?
    errors.add(:base, "You have too many manifested jumpers") if max_slots < load.slots.count
  end

  # The vehicles the load has after this change: the ones given, or the one given in place of the carrying ones (the
  # support vehicles stay); nil when the vehicles do not change
  def new_vehicle_roles
    @new_vehicle_roles ||=
      if vehicles
        vehicles.map(&:symbolize_keys)
      elsif vehicle
        [{ vehicle: vehicle, role: "carrying" }] +
          load.load_vehicles.select(&:support?).map { |support| { vehicle: support.vehicle, role: "support" } }
      end
  end

  def vehicle_names
    new_vehicle_roles.map { |entry| "#{entry[:vehicle].name} (#{entry[:vehicle].registration})" }.to_sentence
  end

  def check_vehicle_change
    return unless new_vehicle_roles

    carrying = new_vehicle_roles.select { |entry| entry[:role].to_s == "carrying" }
    capacity = carrying.sum { |entry| entry[:vehicle].capacity.to_i }
    if capacity < load.slots.count
      errors.add(:base, "These vehicles cannot fit all manifested jumpers")
      return
    end

    kept_ids = new_vehicle_roles.pluck(:vehicle).map(&:id)
    load.load_vehicles.each do |load_vehicle|
      if kept_ids.exclude?(load_vehicle.vehicle_id) && load_vehicle.slots_count.positive?
        errors.add(:base, "#{load_vehicle.vehicle.name} has manifested jumpers and cannot be taken off the load")
      end
    end
    @new_capacity = capacity
  end

  def update_load
    # An older version than the stored one makes the save raise StaleObjectError, the mutation answers CONFLICT
    load.lock_version = lock_version if lock_version
    load.assign_attributes(dispatch_at: dispatch_at) if inputs.given?(:dispatch_at)
    load.destination_ids = destination_ids unless destination_ids.nil?
    load.vehicle_roles = new_vehicle_roles if new_vehicle_roles
    load.enforce_crew_permissions = true
    load.crew_entries = crew.map(&:symbolize_keys) if crew
    load.gca = gca if gca
    load.pilot = pilot if pilot
    load.load_master = load_master if load_master
    load.assign_attributes(
      {
        name: name,
        max_slots: max_slots || @new_capacity || load.max_slots || load.capacity,
      }.compact
    )
  end

  def save
    errors.merge!(load.errors) unless load.save
  end

  # The state is not assigned: it changes through the state machine, which refuses transitions that make no sense
  # (BUG-035) and keeps the jump counters right. A call time without a state means a boarding call, clearing it means
  # cancelling the call.
  def change_state
    target = requested_state
    return if target.blank? || target == load.state

    case target
    when "completed"
      compose(::Manifest::FinalizeLoad, load: load, access_context: access_context)
    when "cancelled"
      compose(::Manifest::CancelLoad, load: load, access_context: access_context)
    else
      event = STATE_EVENTS.fetch(target)
      return if load.public_send(event)

      # The state machine saves the load, so a rule of the load (destinations) says why it refused
      reason = load.errors.full_messages_for(:destinations).to_sentence.presence
      errors.add(:base, reason || "Load ##{load.load_number} can't go from #{load.state.humanize.downcase} to #{target.humanize.downcase}")
    end
  end

  def requested_state
    return state if state.present?
    return unless inputs.given?(:dispatch_at)

    dispatch_at.present? ? "boarding" : "open"
  end
end
