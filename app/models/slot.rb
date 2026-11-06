# frozen_string_literal: true

# == Schema Information
#
# Table name: slots
#
#  id                :bigint           not null, primary key
#  ticket_type_id    :bigint
#  load_id           :bigint
#  activity_type_id      :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  body_mass_kg       :float
#  guest_id      :bigint
#  is_paid           :boolean
#  transaction_id    :bigint
#  escort_slot_id :bigint
#  group_number      :integer          default(0), not null
#  membership_id  :bigint
#  destination_id :bigint
#  prepaid        :boolean          default(FALSE), not null
#
class Slot < ApplicationRecord
  include DailyLogEntry::Slot

  delegate :user, to: :membership, allow_nil: true

  belongs_to :membership, optional: true
  belongs_to :created_by, class_name: "Membership", optional: true
  belongs_to :guest, optional: true
  belongs_to :ticket_type
  belongs_to :load
  # The vehicle of the load this slot rides in, when the load has several that carry (nil: the load's only one)
  belongs_to :load_vehicle, optional: true
  belongs_to :activity_type, optional: true
  # The place this slot goes to when destinations are per slot (skydiving: its altitude); the ticket type's by default
  belongs_to :destination, optional: true
  has_one :operator, through: :load

  has_one :order, as: :item, required: false

  # The order that still stands for the slot. A slot that was moved has the refunded order of its first load before it,
  # and `order` may be that one: refunding it again charges the member (BUG-104)
  def current_order
    Order.where(item: self).where.not(state: %i(refunded cancelled)).order(:id).last
  end
  has_many :receipts, through: :order
  has_many :transactions, through: :receipts

  # A slot of a ticket type that requires an escort has the slots of its guests (`guest_slots`, up to the ticket's
  # `escort_capacity`); a guest's slot points back to its escort (P7.15). Guests ride on the same load and vehicle.
  belongs_to :escort_slot, optional: true, class_name: "Slot", inverse_of: :guest_slots
  has_many :guest_slots, class_name: "Slot", foreign_key: :escort_slot_id, inverse_of: :escort_slot, dependent: :destroy

  # The items the slot uses (a skydiver's rig; a diver's BCD, regulator and wetsuit)
  has_many :slot_equipment, dependent: :destroy
  has_many :equipment, through: :slot_equipment
  has_many :slot_extras, dependent: :destroy
  has_many :extras, through: :slot_extras
  has_many :notifications, as: :resource
  scope :ready, -> {
                  where.not(membership: nil).or(where.not(guest: nil)).where.not(ticket_type: nil, load: nil, activity_type: nil)
                }

  counter_culture %i(load operator), column_name: :slots_count
  # The slots of each vehicle of a load with several (P7.9)
  counter_culture :load_vehicle
  # The load's counters: every slot counts in slots_count, only the ready ones in ready_slots_count. The second counter
  # needs its own column_name, without it counter_culture also increments slots_count (BUG-019).
  counter_culture :load
  counter_culture :load,
                  column_name: proc { |slot| slot.ready? ? "ready_slots_count" : nil },
                  column_names: -> { { Slot.ready => "ready_slots_count" } }

  # Only industries with the activities module (skydiving: jump types) have slots with an activity
  validates :activity_type, presence: true, if: -> { operator&.module?(:activities) }
  before_validation :default_destination, on: :create
  validates :destination, presence: true, if: -> { operator&.destinations_per_slot? }
  validate :destination_of_operator, :load_vehicle_of_load, :equipment_of_member_or_operator
  validate :escort_of_load
  # Everything the rules of Eligibility say about the slot: on create, and when what it is for changes
  validate :eligible, if: -> { new_record? || eligibility_changed? }

  after_create do
    Notification.create(
      received_by: membership,
      notification_type: :user_manifested,
      message: "You have been manifested on Load ##{load.load_number}",
      resource: self
    )
  end

  before_destroy do
    Notification.create(
      received_by: membership,
      notification_type: :user_manifested,
      message: "You're no longer manifested on Load ##{load.load_number}",
      resource: self
    )
  end

  # What the slot costs: the ticket and the add-ons, in cents
  def cost_cents
    extras.sum { |extra| extra.cost_cents || 0 } + (ticket_type.cost_cents || 0)
  end

  def ready?
    return false if ticket_type.blank?
    return false if load.blank?
    return false if activity_type.blank?
    guest.present? || membership.present?
  end

  # Pounds per square foot under the slot's rig; only operators with the rig kind of skydiving have one
  def wing_loading
    return unless body_mass_kg

    rig = equipment.find { |item| item.kind.key == Skydiving::Rigs::KIND }
    weight = body_mass_kg
    weight += guest_slots.sum { |guest_slot| guest_slot.body_mass_kg || 0 }
    Skydiving::Rigs.wing_loading(rig, weight)
  end

  def has_guest?
    guest_slots.any?
  end

  def is_guest?
    guest.present?
  end

  private

  def default_destination
    self.destination ||= ticket_type&.default_destination if operator&.destinations_per_slot?
  end

  def destination_of_operator
    return if destination.nil? || destination.operator_id == operator&.id

    errors.add(:destination, :invalid)
  end

  # Each item is the member's own or the operator's
  def equipment_of_member_or_operator
    return if equipment.empty?

    foreign = equipment.reject do |item|
      item.user_id.present? ? item.user_id == membership&.user_id : item.operator_id == load&.operator_id
    end
    errors.add(:equipment, :invalid) if foreign.any?
  end

  def load_vehicle_of_load
    return if load_vehicle.nil?

    errors.add(:load_vehicle, :invalid) unless load_vehicle.load_id == load_id && load_vehicle.carrying?
  end

  def eligibility_changed?
    will_save_change_to_load_id? || will_save_change_to_ticket_type_id? || will_save_change_to_activity_type_id? ||
      will_save_change_to_body_mass_kg? || will_save_change_to_load_vehicle_id? || will_save_change_to_group_number?
  end

  def eligible
    Eligibility.failures(Eligibility::Context.new(self)).each { |result| errors.add(result.field || :base, result.message) }
  end

  # A guest rides on the load (and the vehicle) of its escort
  def escort_of_load
    return if escort_slot.nil?

    errors.add(:escort_slot, "must be on the same load") unless escort_slot.load_id == load_id
    errors.add(:escort_slot, "must be in the same vehicle") if load_vehicle_id && escort_slot.load_vehicle_id != load_vehicle_id
    errors.add(:guest, :blank) if guest.nil?
  end
end
