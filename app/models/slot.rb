# frozen_string_literal: true

# == Schema Information
#
# Table name: slots
#
#  id                :bigint           not null, primary key
#  ticket_type_id    :bigint
#  load_id           :bigint
#  rig_id            :bigint
#  jump_type_id      :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  exit_weight       :float
#  passenger_id      :bigint
#  is_paid           :boolean
#  transaction_id    :bigint
#  passenger_slot_id :bigint
#  group_number      :integer          default(0), not null
#  dropzone_user_id  :bigint
#
class Slot < ApplicationRecord
  include MasterLogEntry::Slot
  delegate :user, to: :dropzone_user, allow_nil: true

  belongs_to :dropzone_user, optional: true
  belongs_to :created_by, class_name: "DropzoneUser", optional: true
  belongs_to :passenger, optional: true
  belongs_to :ticket_type
  belongs_to :load
  belongs_to :rig, optional: true
  belongs_to :jump_type
  has_one :dropzone, through: :load

  has_one :order, as: :item, required: false
  has_many :receipts, through: :order
  has_many :transactions, through: :receipts

  belongs_to :passenger_slot, optional: true, class_name: "Slot"

  has_many :slot_extras
  has_many :extras, through: :slot_extras
  has_many :notifications, as: :resource
  scope :ready, -> {
                  where.not(dropzone_user: nil).or(where.not(passenger: nil)).where.not(ticket_type: nil, load: nil, jump_type: nil)
                }

  counter_culture %i(load plane dropzone), column_name: :slots_count
  counter_culture :load, column_name: :slots_count
  counter_culture :load,
                  column_names: -> {
                                  {
                                    Slot.ready => "ready_slots_count",
                                  }
                                }

  validate :available?,
           :double_manifest?,
           :allowed_jump_type?,
           :affordable?,
           on: :create

  after_create do
    Notification.create(
      received_by: dropzone_user,
      notification_type: :user_manifested,
      message: "You have been manifested on Load ##{load.load_number}",
      resource: self
    )
  end

  before_destroy do
    Notification.create(
      received_by: dropzone_user,
      notification_type: :user_manifested,
      message: "You're no longer manifested on Load ##{load.load_number}",
      resource: self
    )
  end

  def cost
    extra_cost = extras.sum(&:cost)
    extra_cost ||= 0
    extra_cost + ticket_type.cost
  end

  def ready?
    return false if ticket_type.blank?
    return false if load.blank?
    return false if jump_type.blank?
    (passenger.present? || dropzone_user.present?)
  end

  def wing_loading
    return unless rig.try(:canopy_size)
    return unless exit_weight
    weight = exit_weight
    weight += (passenger_slot.exit_weight || 0) if has_passenger?

    weight_in_lbs = weight * 2.20462
    weight_in_lbs /= rig.canopy_size
    weight_in_lbs
  end

  def has_passenger?
    passenger_slot.present?
  end

  def is_passenger?
    passenger.present?
  end

  private

  def required_slots
    return 2 if has_passenger?
    1
  end

  def available?
    errors.add(:base, "No slots available on this load") if load.available_slots < required_slots
  end

  def double_manifest?
    return if dropzone.allow_double_manifesting?
    return if is_passenger?
    # Check if the user is manifest on any loads that have
    # not yet been dispatched
    return unless dropzone_user.slots.where(load: dropzone_user.dropzone.loads.today.active).where.not(id: id).exists?
    return if created_by.can?(:createDoubleSlot)
    errors.add(:base, "Double-manifesting is not allowed")
  end

  def affordable?
    return true if is_passenger?
    return if dropzone.allow_negative_credits?
    return unless dropzone.require_credits?
    return unless dropzone.is_credit_system_enabled?
    credits = dropzone_user.credits || 0
    errors.add(:base, "Not enough credits to manifest for this jump") if cost > credits
  end

  def allowed_jump_type?
    return true if is_passenger? && ticket_type.is_tandem?
    return if jump_type.allowed_for?(dropzone_user)
    return unless dropzone.require_license?
    errors.add(:jump_type, "User cannot be manifested for #{jump_type.name} jumps")
  end
end
