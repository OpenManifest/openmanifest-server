# frozen_string_literal: true

# == Schema Information
#
# Table name: slots
#
#  id                :integer          not null, primary key
#  ticket_type_id    :integer
#  load_id           :integer
#  rig_id            :integer
#  jump_type_id      :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  exit_weight       :float
#  passenger_id      :integer
#  is_paid           :boolean
#  transaction_id    :integer
#  passenger_slot_id :integer
#  group_number      :integer          default(0), not null
#  dropzone_user_id  :integer
#
class Slot < ApplicationRecord
  belongs_to :dropzone_user, optional: true
  delegate :user, to: :dropzone_user
  
  belongs_to :passenger, optional: true
  belongs_to :ticket_type
  belongs_to :load
  belongs_to :rig, optional: true
  belongs_to :jump_type

  belongs_to :passenger_slot, optional: true, class_name: "Slot"
  belongs_to :payment, foreign_key: :transaction_id, class_name: "Transaction", optional: true

  has_many :slot_extras
  has_many :extras, through: :slot_extras

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


  def reserve_transaction!
    # Tandem passengers are not real accounts and will
    # not be charged credits:
    return unless user.present?

    # Find Dropzone user:
    if dropzone_user
      message = [
        "#{ticket_type.name} (#{ticket_type.cost})"
      ] + (extras || []).map { |e| "#{e.name} (#{e.cost})" }

      
      update(
        payment: Transaction.create(
          status: :reserved,
          message: message.join(" + "),
          # Make negative to charge credits
          amount: cost * -1,
          dropzone_user: dropzone_user
        )
      ) unless payment.present?
    end
  end

  def charge_credits!
    # Tandem passengers are not real accounts and will
    # not be charged credits:
    return unless dropzone_user.present?
    reserve_transaction! unless payment.present?
    
    payment.update(
      status: :paid,
    )
  end

  def refund_credits!
    return unless payment.present?
    payment.destroy
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
      weight_in_lbs = exit_weight * 2.20462
      weight_in_lbs /= canopy_size
    end
  end
end
