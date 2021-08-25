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
  belongs_to :dropzone_user, optional: true
  delegate :user, to: :dropzone_user, allow_nil: true

  belongs_to :passenger, optional: true
  belongs_to :ticket_type
  belongs_to :load
  belongs_to :rig, optional: true
  belongs_to :jump_type

  has_one :order, as: :item, required: false
  has_many :receipts, through: :order
  has_many :transactions, through: :receipts

  belongs_to :passenger_slot, optional: true, class_name: 'Slot'

  has_many :slot_extras
  has_many :extras, through: :slot_extras
  has_many :notifications, as: :resource

  counter_culture %i[load plane dropzone], column_name: :slots_count

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
    extra_cost = extras.map(&:cost).reduce(&:+)
    extra_cost ||= 0
    extra_cost + ticket_type.cost
  end

  def ready?
    (passenger.present? || user.present?) && ticket_type.present? && load.present? && jump_type.present?
  end

  def wing_loading
    if rig && rig.canopy_size && exit_weight
      weight = exit_weight
      weight += (passenger_slot.exit_weight || 0) if has_passenger?

      weight_in_lbs = weight * 2.20462
      weight_in_lbs /= rig.canopy_size
      weight_in_lbs
    end
  end

  def has_passenger?
    passenger_slot.present?
  end
end
