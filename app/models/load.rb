# frozen_string_literal: true

# == Schema Information
#
# Table name: loads
#
#  id             :integer          not null, primary key
#  dispatch_at    :datetime
#  has_landed     :boolean
#  plane_id       :integer          not null
#  load_master_id :integer
#  gca_id         :integer
#  pilot_id       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  name           :string
#  max_slots      :integer          default(0)
#  is_open        :boolean
#
class Load < ApplicationRecord
  belongs_to :plane
  belongs_to :load_master, class_name: "DropzoneUser", optional: true, foreign_key: :load_master_id
  belongs_to :gca, class_name: "DropzoneUser", optional: true, foreign_key: :gca_id
  belongs_to :pilot, class_name: "DropzoneUser", optional: true, foreign_key: :pilot_id

  has_many :slots
  before_save do 
    # Default to open
    assign_attributes(state: :open)
  end
 
  after_save :notify!,
             :change_state!

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


  def load_number
    load_index = plane.dropzone.loads.where(
      "loads.created_at > ?",
      DateTime.now.beginning_of_day
    ).order(created_at: :asc).find_index do |load|
      load.id == id
    end

    (load_index || 0) + 1
  end

  def notify!
    if saved_change_to_dispatch_at?
      if dispatch_at_was.nil? && !dispatch_at.nil?
        slots.each do |slot|
          if slot.dropzone_user.present?
            Notification.create(
              message: "Load ##{load_number} take off at #{dispatch_at.strftime("%H:%M")}",
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
              message: "Load ##{load_number} call changed to take off at #{dispatch_at.strftime("%H:%M")}",
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
end
