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
  validate :escort_of_load, :guests_within_capacity, :escort_meets_requirements
  validate :load_vehicle_has_room, if: -> { load_vehicle && (new_record? || load_vehicle_id_changed?) }
  validate :available?,
           :double_manifest?,
           :allowed_activity_type?,
           :certified_for_ticket?,
           :membership_in_date?,
           :affordable?,
           on: :create

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

  def load_vehicle_has_room
    return if load_vehicle.available_slots >= required_slots

    errors.add(:base, "No slots available in #{load_vehicle.vehicle.name}")
  end

  # The seats the slot takes: its own and the guests'
  def required_slots
    1 + guest_slots.size
  end

  # A guest rides on the load (and the vehicle) of its escort
  def escort_of_load
    return if escort_slot.nil?

    errors.add(:escort_slot, "must be on the same load") unless escort_slot.load_id == load_id
    errors.add(:escort_slot, "must be in the same vehicle") if load_vehicle_id && escort_slot.load_vehicle_id != load_vehicle_id
    errors.add(:guest, :blank) if guest.nil?
  end

  # An escort takes the guests its ticket type allows
  def guests_within_capacity
    return if guest_slots.empty?

    unless ticket_type&.requires_escort?
      errors.add(:base, "#{ticket_type&.name || 'This ticket'} does not take guests")
      return
    end
    return if guest_slots.size <= ticket_type.escort_capacity

    errors.add(:base, "#{ticket_type.name} takes at most #{ticket_type.escort_capacity} #{'guest'.pluralize(ticket_type.escort_capacity)} for each escort")
  end

  # The escort holds the qualification and the crew role's permission the ticket type asks for
  def escort_meets_requirements
    return unless new_record? && guest_slots.any? && membership && ticket_type
    return if created_by&.can?(:createUserSlot) && operator&.allow_manifest_bypass?

    unmet = ticket_type.unmet_escort_requirements(membership)
    return if unmet.empty?

    errors.add(:base, "#{membership.user.name} cannot escort guests: missing #{unmet.map { |kind| kind.to_s.humanize.downcase }.join(', ')}")
  end

  def available?
    errors.add(:base, "No slots available on this load") if load.available_slots < required_slots
  end

  def membership_in_date?
    return if is_guest?
    return if (membership.expires_at || 1.second.ago) > DateTime.current
    return unless operator.require_membership?
    return if created_by&.can?(:createUserSlot) && operator.allow_manifest_bypass?
    errors.add(:base, "#{membership.user.name}'s membership has expired")
  end

  def double_manifest?
    return if operator.allow_double_manifesting?
    return if is_guest?
    # Check if the user is manifest on any loads that have
    # not yet been dispatched
    return unless membership.slots.where(load: operator.loads.on(operator.today).active).where.not(id: id).exists?
    return if created_by&.can?(:createDoubleSlot) && operator.allow_manifest_bypass?
    errors.add(:base, "Double-manifesting is not allowed")
  end

  def affordable?
    return true if is_guest?
    return if operator.allow_negative_credits?
    return unless operator.require_credits?
    return if created_by&.can?(:createUserSlot) && operator.allow_manifest_bypass?
    credits = membership.credits_cents || 0
    errors.add(:base, "Not enough credits to manifest for this jump") if cost_cents > credits
  end

  # The ticket type asks for a minimum rank or a qualification, and so may an extra
  def certified_for_ticket?
    return if is_guest? || membership.blank?
    return unless operator.module?(:certifications)

    unmet = ticket_type.unmet_certification_requirements(membership)
    extras.each do |extra|
      unmet << :qualification unless membership.user.qualified_for?(extra.required_qualification)
    end
    return if unmet.empty?
    return if created_by&.can?(:createUserSlot) && operator.allow_manifest_bypass?

    errors.add(:base, "#{membership.user.name} is missing a certification: #{unmet.uniq.map { |kind| kind.to_s.humanize.downcase }.join(', ')}")
  end

  def allowed_activity_type?
    return if activity_type.blank?
    return true if is_guest? && ticket_type.requires_escort?
    return if activity_type.allowed_for?(membership)
    return unless operator.require_certification?
    return if created_by&.can?(:createUserSlot) && operator.allow_manifest_bypass?
    errors.add(:activity_type, "User cannot be manifested for #{activity_type.name} jumps")
  end
end
