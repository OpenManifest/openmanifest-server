# frozen_string_literal: true

# == Schema Information
#
# Table name: loads
#
#  id             :integer          not null, primary key
#  dispatch_at    :datetime
#  has_landed     :boolean
#  plane_id       :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  name           :string
#  max_slots      :integer          default(0)
#  is_open        :boolean
#  gca_id         :integer
#  load_master_id :integer
#  pilot_id       :integer
#  state          :integer
#
class Load < ApplicationRecord
  scope :today, -> { where(created_at: DateTime.now.beginning_of_day..DateTime.now.end_of_day) }
  belongs_to :plane
  belongs_to :load_master, class_name: "DropzoneUser", optional: true, foreign_key: :load_master_id
  belongs_to :gca, class_name: "DropzoneUser", optional: true, foreign_key: :gca_id
  belongs_to :pilot, class_name: "DropzoneUser", optional: true, foreign_key: :pilot_id

  has_many :notifications, as: :resource
  has_many :slots
  before_save do 
    # Default to open
    assign_attributes(state: :open) if state.nil?
  end
 
  after_save :notify!,
             :change_state!
  before_create :set_load_number

  enum state: [
    :open,
    :boarding_call,
    :in_flight,
    :landed,
    :cancelled
  ]

  # Changes the state of the load, which affects whether
  # users get charged credits or not, and what notifications
  # are sent to the user. The state changes when dispatch_at
  # is changed
  def change_state!
    # When the plane is marked as landed, charge credits
    if saved_change_to_has_landed? && has_landed?
      update(state: :landed)
      if plane.dropzone.is_credit_system_enabled?
        # Charge users credits
        slots.each(&:charge_credits!)
      end
    # Change state to boarding call and notify everyone
    elsif saved_change_to_dispatch_at? && dispatch_at
      update(state: :boarding_call)

    # Change state back to open if dispatch_at is reset
    elsif saved_change_to_dispatch_at? && dispatch_at.nil?
      update(state: :open)
    end

    # Refund credits when load is cancelled
    if saved_change_to_state? && state == 'cancelled'
      slots.each(&:refund_credits!)
    end
  end


  def notify!
    if saved_change_to_dispatch_at?
      if dispatch_at_was.nil? && !dispatch_at.nil?
        slots.each do |slot|
          if slot.dropzone_user.present?
            Notification.create(
              message: "Load ##{load_number} take off at #{dispatch_at.in_time_zone(plane.dropzone.time_zone).strftime("%H:%M")}",
              resource: self,
              received_by: slot.dropzone_user,
              notification_type: :boarding_call
            )
          end
        end
      elsif dispatch_at.nil?
        slots.each do |slot|
          if slot.dropzone_user.present?
            Notification.create(
              message: "Load ##{load_number} call canceled",
              resource: self,
              received_by: slot.dropzone_user,
              notification_type: :boarding_call_canceled
            )
          end
        end
      else
        slots.each do |slot|
          if slot.dropzone_user.present?
            Notification.create(
              message: "Load ##{load_number} call changed to take off at #{dispatch_at.in_time_zone(plane.dropzone.time_zone).strftime("%H:%M")}",
              resource: self,
              received_by: slot.dropzone_user,
              notification_type: :boarding_call
            )
          end
        end
      end
    end
  end

  def ready?
    gca.present? && load_master.present? && plane.present? && slots.select(&:ready?).count >= plane.min_slots
  end

  private
  def set_load_number
    assign_attributes(load_number: plane.dropzone.loads.today.count + 1)
  end
end
