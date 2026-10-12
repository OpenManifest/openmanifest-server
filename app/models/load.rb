# frozen_string_literal: true

# == Schema Information
#
# Table name: loads
#
#  id             :bigint           not null, primary key
#  dispatch_at    :datetime
#  has_completed     :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  name           :string
#  max_slots      :integer          default(0)
#  is_open        :boolean
#  state          :integer
#  load_number    :integer
#
class Load < ApplicationRecord
  include Discard::Model

  # Must be declared before the state machine: state_machines-activerecord 0.200 only integrates with an enum that
  # already exists (otherwise new loads have a nil state and every event raises "nil is not a known state value").
  enum :state, { :open => 0, :boarding => 1, :departed => 2, :completed => 3, :cancelled => 4 }

  include StateMachines::LoadState
  include DailyLogEntry::Load

  belongs_to :operator

  validate :destination_called, if: -> { boarding? }
  before_validation :apply_crew_requests
  validate :crew_known, :crew_required, :crew_permitted, if: -> { operator.present? }
  validate :vehicles_allowed, :vehicle_free, if: -> { operator.present? }

  # Set by the interactions that change a load for somebody: the members they put on the crew must be able to fill the role
  attr_accessor :enforce_crew_permissions

  has_many :notifications, as: :resource
  has_many :slots, dependent: :destroy
  # The vehicles of the load (P7.9): those that carry participants first, in the order they were given
  has_many :load_vehicles, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :load, autosave: true
  has_many :vehicles, through: :load_vehicles
  # Who fills the crew roles of the load (P7.10), for the load or for one of its vehicles. After the vehicles: a vehicle
  # that is new is saved before the assignments that name it.
  has_many :crew_assignments, class_name: "LoadCrewAssignment", dependent: :destroy, inverse_of: :load, autosave: true
  # Per-load destinations (the boat visits site 1, then site 2), in the order of the visit
  has_many :load_destinations, -> { order(:position) }, dependent: :destroy, inverse_of: :load
  has_many :destinations, through: :load_destinations

  counter_culture :operator

  before_validation :set_operator_and_date, on: :create
  # The column's default is 0: a load made without a limit has the seats of its vehicles
  before_validation :default_max_slots, on: :create
  before_create :set_load_number
  # Once per change, after the transaction (BUG-036)
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update

  scope :active, -> { where(dispatch_at: nil) }
  # The loads of a day at an operator: its own day, whatever the zone of the server is
  scope :on, ->(date) { where(load_date: date) }
  scope :today_at, ->(operator) { where(operator_id: operator.id, load_date: operator.today) }
  scope :finalized, -> { where.not(state: %i(cancelled open)) }

  # Replaces the stops of the load by these destinations, in this order (per-load scope)
  def destination_ids=(ids)
    ids = Array(ids).map(&:to_i)
    self.load_destinations = ids.each_with_index.map do |destination_id, position|
      load_destinations.find { |stop| stop.destination_id == destination_id && stop.position == position } ||
        load_destinations.build(destination_id: destination_id, position: position)
    end
  end

  # The vehicles of the load that carry participants, whether they are saved yet or not
  def carrying_load_vehicles = load_vehicles.reject { |load_vehicle| load_vehicle.marked_for_destruction? || load_vehicle.support? }

  # The vehicle the load goes with: the first one that carries participants (the only one, for operators without the
  # multi_vehicle module)
  def vehicle = carrying_load_vehicles.first&.vehicle

  # Replaces the vehicles of the load by this one, carrying. The support vehicles stay.
  def vehicle=(vehicle)
    self.vehicle_roles = [{ vehicle: vehicle, role: "carrying" }] + support_load_vehicles.map { |lv| { vehicle: lv.vehicle, role: "support" } }
  end

  # Replaces the vehicles of the load, in this order: `[{ vehicle: Vehicle, role: "carrying" | "support" }]`. A vehicle that
  # is on the load already keeps its row (and its slots).
  def vehicle_roles=(entries)
    kept = []
    entries.each_with_index do |entry, position|
      vehicle = entry.fetch(:vehicle)
      role = (entry[:role] || "carrying").to_s
      row = load_vehicles.find { |load_vehicle| load_vehicle.vehicle_id == vehicle.id && kept.exclude?(load_vehicle) } ||
            load_vehicles.build(vehicle: vehicle)
      row.assign_attributes(role: role, position: position)
      kept << row
    end
    load_vehicles.each { |load_vehicle| load_vehicle.mark_for_destruction if kept.exclude?(load_vehicle) }
    move_crew_to_replacement(kept)
  end

  # The seats of the vehicles that carry participants
  def capacity = carrying_load_vehicles.sum(&:capacity)

  # The assignments of the crew, whether they are saved yet or not
  def current_crew_assignments = crew_assignments.reject(&:marked_for_destruction?)

  # Who fills the role with this key (the first, for a role per vehicle)
  def crew_member(key)
    requested = (@crew_requests || {})[key.to_s]
    return requested[:membership] if requested

    current_crew_assignments.find { |assignment| assignment.crew_role.key == key.to_s }&.membership
  end

  # Fills the role with this key for the load, or for the first vehicle that carries when the role is per vehicle. The
  # role is looked up when the load is validated (the operator may not be set yet). `nil` empties the role.
  %w(pilot gca load_master).each do |key|
    define_method(key) { crew_member(key) }
    define_method(:"#{key}=") { |membership| (@crew_requests ||= {})[key] = { membership: membership } }
  end

  # Replaces the whole crew: `[{ crew_role: CrewRole, membership: Membership, load_vehicle: LoadVehicle | nil, vehicle: Vehicle | nil }]`.
  # For a role per vehicle name the vehicle of the load: its row (`load_vehicle`), or the `vehicle` itself.
  def crew_entries=(entries)
    @crew_requests = nil
    crew_assignments.each(&:mark_for_destruction)
    entries.each do |entry|
      load_vehicle = entry[:load_vehicle]
      if load_vehicle.nil? && entry[:vehicle]
        load_vehicle = load_vehicles.find { |row| row.vehicle_id == entry[:vehicle].id && !row.marked_for_destruction? }
      end
      crew_assignments.build(crew_role: entry.fetch(:crew_role), membership: entry.fetch(:membership), load_vehicle: load_vehicle)
    end
  end

  # Seats of the vehicles that crew with a seat of their own take
  def crew_seats = current_crew_assignments.count { |assignment| assignment.crew_role.occupies_slot }

  def ready?
    return false if carrying_load_vehicles.empty?
    return false unless operator.crew_roles.kept.all? { |role| crew_filled?(role) }

    ready_slots_count >= carrying_load_vehicles.sum { |load_vehicle| load_vehicle.vehicle.min_capacity.to_i }
  end

  def available_slots
    (max_slots || capacity) - (slots_count || 0) - crew_seats
  end

  def occupied_slots
    (max_slots || capacity) - available_slots
  end

  def next_group_number
    current_highest_group_number + 1
  end

  def current_highest_group_number
    return 0 unless persisted?
    slots.maximum(:group_number) || 0
  end

  # Push an update to graphql subscriptions over websockets
  def broadcast_update
    DzSchema.subscriptions.trigger(
      # Field name
      :load_updated,
      # Arguments
      { load_id: id.to_s },
      # Object
      { load_id: id.to_s }
    )
  end

  def broadcast_create
    DzSchema.subscriptions.trigger(
      # Field name
      :load_created,
      # Arguments
      { operator_id: operator_id.to_s },
      # Object
      { load_id: id.to_s }
    )
  end

  # Adds `by` (1 or -1) jump to every jumper on the load, and to the jumper's operator count when it is their first (or,
  # when taking it back, their only) jump at the operator. Called by the state machine when the load lands or a completed
  # load is reopened.
  def count_jumps!(by)
    ids = slots.where.not(membership_id: nil).pluck(:membership_id)
    return if ids.empty?

    user_ids = Membership.where(id: ids).pluck(:user_id)
    operator_first_ids = Membership.where(id: ids, load_count: by.positive? ? 0 : 1).pluck(:user_id)

    Membership.update_counters(ids, load_count: by)
    User.update_counters(operator_first_ids, operator_count: by)
    User.update_counters(user_ids, load_count: by)
  end

  private

  # Operators whose loads go to places (per-load scope) cannot call a load that has no destination
  def destination_called
    return unless operator&.destinations_per_load?
    return if load_destinations.any? { |stop| !stop.marked_for_destruction? }

    errors.add(:destinations, "must include at least one place before the load is called")
  end

  # One vehicle that carries swapped for another keeps its crew (the pilot of the aircraft that was changed)
  def move_crew_to_replacement(kept)
    removed = load_vehicles.select { |row| row.marked_for_destruction? && row.carrying? }
    added = kept.select { |row| row.new_record? && row.carrying? }
    return unless removed.size == 1 && added.size == 1

    crew_assignments.each do |assignment|
      assignment.load_vehicle = added.first if assignment.load_vehicle.equal?(removed.first) || (removed.first.id && assignment.load_vehicle_id == removed.first.id)
    end
  end

  # The role is filled for the load, or for every vehicle it applies to
  def crew_filled?(role)
    assignments = current_crew_assignments.select { |assignment| assignment.crew_role_id == role.id || assignment.crew_role.equal?(role) }
    return assignments.size == 1 if role.load_scope?

    carrying_load_vehicles.select { |load_vehicle| role.applies_to?(load_vehicle) }.all? do |load_vehicle|
      assignments.any? { |assignment| assignment.load_vehicle.equal?(load_vehicle) || (assignment.load_vehicle_id && assignment.load_vehicle_id == load_vehicle.id) }
    end
  end

  # Turns what `pilot=`, `gca=` and `load_master=` were given into assignments of the operator's roles of that key
  def apply_crew_requests
    return if @crew_requests.blank? || operator.nil?

    @crew_unknown = []
    @crew_requests.each do |key, request|
      role = operator.crew_roles.kept.find_by(key: key)
      current = crew_assignments.select { |assignment| assignment.crew_role_id == role&.id && !assignment.marked_for_destruction? }
      membership = request[:membership]
      next if membership.nil? && role.nil?

      if role.nil?
        @crew_unknown << key
        next
      end
      next if membership && current.size == 1 && current.first.membership_id == membership.id

      current.each(&:mark_for_destruction)
      next if membership.nil?

      load_vehicle = role.vehicle_scope? ? carrying_load_vehicles.find { |candidate| role.applies_to?(candidate) } : nil
      crew_assignments.build(crew_role: role, membership: membership, load_vehicle: load_vehicle)
    end
    @crew_requests = nil
  end

  def crew_known
    (@crew_unknown || []).each { |key| errors.add(:base, "This operator has no #{key.humanize.downcase} role") }
  end

  # Every required role is filled: once for the load, or once for each vehicle it applies to
  def crew_required
    operator.crew_roles.kept.where(required: true).ordered.each do |role|
      errors.add(:base, "Every load needs a #{role.name}") unless crew_filled?(role)
    end
  end

  # New crew (and crew changed to somebody else) hold the permission of the role, when the interaction asks for it
  def crew_permitted
    return unless enforce_crew_permissions

    current_crew_assignments.select { |assignment| assignment.new_record? || assignment.membership_id_changed? }.each do |assignment|
      next if assignment.crew_role.fillable_by?(assignment.membership)

      errors.add(:base, "#{assignment.membership.user&.name || 'This member'} cannot act as #{assignment.crew_role.name}")
    end
  end

  def support_load_vehicles = load_vehicles.select { |load_vehicle| !load_vehicle.marked_for_destruction? && load_vehicle.support? }

  # Without the multi_vehicle module a load has exactly one vehicle, and it carries; with it, at least one carries
  def vehicles_allowed
    kept = load_vehicles.reject(&:marked_for_destruction?)
    carrying = kept.count(&:carrying?)
    if operator.module?(:multi_vehicle)
      errors.add(:base, "A load needs a vehicle that carries participants") if carrying.zero?
    else
      errors.add(:base, "A load has one vehicle, and it carries participants") if kept.size != 1 || carrying != 1
    end
  end

  # A vehicle goes with one load at a time: not on another load that is called or on its way, unless that load is more
  # than `settings.vehicle_turnaround_minutes` away (0, the default: whatever the time). Only with the multi_vehicle
  # module: a dropzone's aircraft keeps its queue of loads.
  def vehicle_free
    return unless operator.module?(:multi_vehicle) && (boarding? || departed?)

    minutes = operator.settings["vehicle_turnaround_minutes"].to_i
    busy = Load.kept.where(state: %i(boarding departed)).where.not(id: id).joins(:load_vehicles).
      where(load_vehicles: { vehicle_id: load_vehicles.reject(&:marked_for_destruction?).map(&:vehicle_id) })
    busy = busy.where(dispatch_at: (dispatch_at - minutes.minutes)..(dispatch_at + minutes.minutes)) if minutes.positive? && dispatch_at
    errors.add(:base, "A vehicle is on another load that is called or on its way") if busy.exists?
  end

  def default_max_slots
    self.max_slots = capacity if max_slots.to_i.zero?
  end

  # A load belongs to the operator of its vehicle, and to the day it was created on in that operator's time zone
  def set_operator_and_date
    self.operator ||= load_vehicles.first&.vehicle&.operator
    return unless operator

    self.load_date ||= (created_at || Time.current).in_time_zone(operator.time_zone).to_date
  end

  # Numbers count up per operator and day, archived loads included (counting the kept loads repeated a number after one
  # was archived, BUG-022). The operator row is locked until the end of the transaction, so concurrent loads of one
  # operator get different numbers; the unique index backs this up.
  def set_load_number
    Operator.where(id: operator_id).lock.pick(:id)
    highest = Load.where(operator_id: operator_id, load_date: load_date).maximum(:load_number) || 0
    assign_attributes(load_number: highest + 1)
  end
end
