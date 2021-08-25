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
  belongs_to :plane
  has_one :dropzone, through: :plane
  scope :today, -> { where(created_at: DateTime.now.beginning_of_day..DateTime.now.end_of_day) }

  belongs_to :load_master, class_name: "DropzoneUser", optional: true, foreign_key: :load_master_id
  belongs_to :gca, class_name: "DropzoneUser", optional: true, foreign_key: :gca_id
  belongs_to :pilot, class_name: "DropzoneUser", optional: true, foreign_key: :pilot_id

  has_many :notifications, as: :resource
  has_many :slots, dependent: :destroy

  counter_culture :dropzone

  before_save do
    # Default to open
    assign_attributes(state: :open) if state.nil?
  end

  after_save :notify!,
             :change_state!,
             :update_counters!
  before_create :set_load_number

  enum state: %i[
    open
    boarding_call
    in_flight
    landed
    cancelled
  ]

  # Changes the state of the load, which affects whether
  # users get charged credits or not, and what notifications
  # are sent to the user. The state changes when dispatch_at
  # is changed
  def change_state!
    # When the plane is marked as landed, charge credits
    if saved_change_to_has_landed? && has_landed?
      update(state: :landed)
    # Change state to boarding call and notify everyone
    elsif saved_change_to_dispatch_at? && dispatch_at
      update(state: :boarding_call)

    # Change state back to open if dispatch_at is reset
    elsif saved_change_to_dispatch_at? && dispatch_at.nil?
      update(state: :open)
    end
  end

  def notify!
    if saved_change_to_dispatch_at?
      if dispatch_at_was.nil? && !dispatch_at.nil?
        slots.each do |slot|
          next unless slot.dropzone_user.present?

          Notification.create(
            message: "Load ##{load_number} take off at #{dispatch_at.in_time_zone(plane.dropzone.time_zone).strftime('%H:%M')}",
            resource: self,
            received_by: slot.dropzone_user,
            notification_type: :boarding_call
          )
        end
      elsif dispatch_at.nil?
        slots.each do |slot|
          next unless slot.dropzone_user.present?

          Notification.create(
            message: "Load ##{load_number} call canceled",
            resource: self,
            received_by: slot.dropzone_user,
            notification_type: :boarding_call_canceled
          )
        end
      else
        slots.each do |slot|
          next unless slot.dropzone_user.present?

          Notification.create(
            message: "Load ##{load_number} call changed to take off at #{dispatch_at.in_time_zone(plane.dropzone.time_zone).strftime('%H:%M')}",
            resource: self,
            received_by: slot.dropzone_user,
            notification_type: :boarding_call
          )
        end
      end
    end
  end

  def ready?
    gca.present? && load_master.present? && plane.present? && slots.count(&:ready?) >= plane.min_slots
  end

  def available_slots
    (max_slots || plane.max_slots) - (slots.count || 0)
  end

  def occupied_slots
    (max_slots || plane.max_slots) - available_slots
  end

  private
    def set_load_number
      Time.use_zone(dropzone.time_zone) do
        assign_attributes(load_number: plane.dropzone.loads.today.count + 1)
      end
    end

    def update_counters!
      if state_changed?
        if state == "landed"
          # Update counters
          ids = slots.where.not(dropzone_user_id: nil).pluck(:dropzone_user_id)
          user_ids = DropzoneUser.where(id: ids).pluck(:user_id)
          first_time_ids = DropzoneUser.where(id: ids, jump_count: 0).pluck(:user_id)

          DropzoneUser.update_counters(ids, jump_count: 1)
          User.update_counters(first_time_ids, dropzone_count: 1)

          # If this is the first jump at the dropzone, also update
          # dropzone count
          User.update_counters(user_ids, jump_count: 1)
        # Reverse the counters if the load marked as
        # not landed again
        elsif state_was == "landed"
          # Update counters
          ids = slots.where.not(dropzone_user_id: nil).pluck(:dropzone_user_id)
          user_ids = DropzoneUser.where(id: ids).pluck(:user_id)
          first_time_ids = DropzoneUser.where(id: ids, jump_count: 0).pluck(:user_id)

          DropzoneUser.update_counters(ids, jump_count: -1)
          User.update_counters(first_time_ids, dropzone_count: -1)

          # If this is the first jump at the dropzone, also update
          # dropzone count
          User.update_counters(user_ids, jump_count: -1)
        end
      end
    end
end
