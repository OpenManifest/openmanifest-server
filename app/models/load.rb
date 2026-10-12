# frozen_string_literal: true

# == Schema Information
#
# Table name: loads
#
#  id             :bigint           not null, primary key
#  dispatch_at    :datetime
#  has_completed     :boolean
#  vehicle_id       :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  name           :string
#  max_slots      :integer          default(0)
#  is_open        :boolean
#  gca_id         :bigint
#  load_master_id :bigint
#  pilot_id       :bigint
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

  belongs_to :vehicle
  belongs_to :operator

  belongs_to :load_master, class_name: "Membership", optional: true
  belongs_to :gca, class_name: "Membership", optional: true
  belongs_to :pilot, class_name: "Membership", optional: true

  validates :gca, presence: { message: "Every load must have a GCA" }
  validates :pilot, presence: { message: "Pilot is required" }
  validate :destination_called, if: -> { boarding? }

  has_many :notifications, as: :resource
  has_many :slots, dependent: :destroy
  # Per-load destinations (the boat visits site 1, then site 2), in the order of the visit
  has_many :load_destinations, -> { order(:position) }, dependent: :destroy, inverse_of: :load
  has_many :destinations, through: :load_destinations

  counter_culture :operator

  before_validation :set_operator_and_date, on: :create
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

  def ready?
    return false if gca.blank?
    return false if load_master.blank?
    return false if vehicle.blank?
    ready_slots_count >= vehicle.min_capacity
  end

  def available_slots
    (max_slots || vehicle.capacity) - (slots_count || 0)
  end

  def occupied_slots
    (max_slots || vehicle.capacity) - available_slots
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
      { operator_id: vehicle.operator_id.to_s },
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

  # A load belongs to the operator of its vehicle, and to the day it was created on in that operator's time zone
  def set_operator_and_date
    self.operator ||= vehicle&.operator
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
