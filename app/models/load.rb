# frozen_string_literal: true

# == Schema Information
#
# Table name: loads
#
#  id             :bigint           not null, primary key
#  dispatch_at    :datetime
#  has_landed     :boolean
#  plane_id       :bigint           not null
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
  enum :state, { :open => 0, :boarding_call => 1, :in_flight => 2, :landed => 3, :cancelled => 4 }

  include StateMachines::LoadState
  include MasterLogEntry::Load

  belongs_to :plane
  belongs_to :dropzone

  belongs_to :load_master, class_name: "DropzoneUser", optional: true
  belongs_to :gca, class_name: "DropzoneUser", optional: true
  belongs_to :pilot, class_name: "DropzoneUser", optional: true

  validates :gca, presence: { message: "Every load must have a GCA" }
  validates :pilot, presence: { message: "Pilot is required" }

  has_many :notifications, as: :resource
  has_many :slots, dependent: :destroy

  counter_culture :dropzone

  before_validation :set_dropzone_and_date, on: :create
  before_create :set_load_number
  # Once per change, after the transaction (BUG-036)
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update

  scope :active, -> { where(dispatch_at: nil) }
  # The loads of a day at a dropzone: its own day, whatever the zone of the server is
  scope :on, ->(date) { where(load_date: date) }
  scope :today_at, ->(dropzone) { where(dropzone_id: dropzone.id, load_date: dropzone.today) }
  scope :finalized, -> { where.not(state: %i(cancelled open)) }

  def ready?
    return false if gca.blank?
    return false if load_master.blank?
    return false if plane.blank?
    ready_slots_count >= plane.min_slots
  end

  def available_slots
    (max_slots || plane.max_slots) - (slots_count || 0)
  end

  def occupied_slots
    (max_slots || plane.max_slots) - available_slots
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
      { dropzone_id: plane.dropzone_id.to_s },
      # Object
      { load_id: id.to_s }
    )
  end

  # Adds `by` (1 or -1) jump to every jumper on the load, and to the jumper's dropzone count when it is their first (or,
  # when taking it back, their only) jump at the dropzone. Called by the state machine when the load lands or a landed
  # load is reopened.
  def count_jumps!(by)
    ids = slots.where.not(dropzone_user_id: nil).pluck(:dropzone_user_id)
    return if ids.empty?

    user_ids = DropzoneUser.where(id: ids).pluck(:user_id)
    dropzone_first_ids = DropzoneUser.where(id: ids, jump_count: by.positive? ? 0 : 1).pluck(:user_id)

    DropzoneUser.update_counters(ids, jump_count: by)
    User.update_counters(dropzone_first_ids, dropzone_count: by)
    User.update_counters(user_ids, jump_count: by)
  end

  private

  # A load belongs to the dropzone of its plane, and to the day it was created on in that dropzone's time zone
  def set_dropzone_and_date
    self.dropzone ||= plane&.dropzone
    return unless dropzone

    self.load_date ||= (created_at || Time.current).in_time_zone(dropzone.time_zone).to_date
  end

  # Numbers count up per dropzone and day, archived loads included (counting the kept loads repeated a number after one
  # was archived, BUG-022). The dropzone row is locked until the end of the transaction, so concurrent loads of one
  # dropzone get different numbers; the unique index backs this up.
  def set_load_number
    Dropzone.where(id: dropzone_id).lock.pick(:id)
    highest = Load.where(dropzone_id: dropzone_id, load_date: load_date).maximum(:load_number) || 0
    assign_attributes(load_number: highest + 1)
  end
end
