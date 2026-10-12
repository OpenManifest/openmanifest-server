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
  string :state, default: nil
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

    if vehicle
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        operator: access_context.operator,
        created_by: access_context.subject,
        message: "#{access_context.user.name} changed the vehicle for load ##{load.load_number} to #{vehicle.name} (#{vehicle.registration})"
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

  def check_vehicle_change
    return unless vehicle
    if vehicle.capacity >= load.slots.count
      load.assign_attributes(max_slots: vehicle.capacity)
    else
      errors.add(:base, "This vehicle cannot fit all manifested jumpers")
    end
  end

  def update_load
    # An older version than the stored one makes the save raise StaleObjectError, the mutation answers CONFLICT
    load.lock_version = lock_version if lock_version
    load.assign_attributes(dispatch_at: dispatch_at) if inputs.given?(:dispatch_at)
    load.assign_attributes(
      {
        gca: gca,
        vehicle: vehicle,
        load_master: load_master,
        pilot: pilot,
        name: name,
        max_slots: max_slots || load.max_slots || load.vehicle.capacity,
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

      errors.add(:base, "Load ##{load.load_number} can't go from #{load.state.humanize.downcase} to #{target.humanize.downcase}")
    end
  end

  def requested_state
    return state if state.present?
    return unless inputs.given?(:dispatch_at)

    dispatch_at.present? ? "boarding" : "open"
  end
end
