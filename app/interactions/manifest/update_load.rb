# frozen_string_literal: true

require "active_interaction"

class Manifest::UpdateLoad < ApplicationInteraction
  allow :updateLoad

  # Arguments
  record :load
  date_time :dispatch_at, default: nil
  string :name, default: nil
  integer :max_slots, default: nil
  object :gca, class: DropzoneUser, default: nil
  object :load_master, class: DropzoneUser, default: nil
  object :pilot, class: DropzoneUser, default: nil
  object :plane, class: Plane, default: nil
  string :state, default: nil

  validates_inclusion_of :state, in: Load.states.keys, allow_nil: true

  # The state the client asks for, and the event of the load's state machine that gets it there
  STATE_EVENTS = {
    "open" => :reopen,
    "boarding_call" => :dispatch,
    "in_flight" => :take_off,
  }.freeze

  steps :check_max_slots,
        :check_plane_change,
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
        dropzone: access_context.dropzone,
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
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.user.name} cancelled call for load ##{load.load_number}"
      )
    end

    if plane
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.user.name} changed the plane for load ##{load.load_number} to #{plane.name} (#{plane.registration})"
      )
    end

    if gca
      compose(
        ::Activity::CreateEvent,
        access_context: access_context,
        resource: load,
        access_level: :user,
        action: :updated,
        dropzone: access_context.dropzone,
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
        dropzone: access_context.dropzone,
        created_by: access_context.subject,
        message: "#{access_context.user.name} changed the load master for load ##{load.load_number} to #{load_master.user.name}"
      )
    end
  end

  def check_max_slots
    return if max_slots.blank?
    errors.add(:base, "You have too many manifested jumpers") if max_slots < load.slots.count
  end

  def check_plane_change
    return unless plane
    if plane.max_slots >= load.slots.count
      load.assign_attributes(max_slots: plane.max_slots)
    else
      errors.add(:base, "This plane cannot fit all manifested jumpers")
    end
  end

  def update_load
    load.assign_attributes(dispatch_at: dispatch_at) if inputs.given?(:dispatch_at)
    load.assign_attributes(
      {
        gca: gca,
        plane: plane,
        load_master: load_master,
        pilot: pilot,
        name: name,
        max_slots: max_slots || load.max_slots || load.plane.max_slots,
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
    when "landed"
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

    dispatch_at.present? ? "boarding_call" : "open"
  end
end
