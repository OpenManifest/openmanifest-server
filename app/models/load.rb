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
  include StateMachines::LoadState

  belongs_to :plane
  has_one :dropzone, through: :plane
  scope :active, -> { where(dispatch_at: nil) }

  belongs_to :load_master, class_name: "DropzoneUser", optional: true, foreign_key: :load_master_id
  belongs_to :gca, class_name: "DropzoneUser", optional: true, foreign_key: :gca_id
  belongs_to :pilot, class_name: "DropzoneUser", optional: true, foreign_key: :pilot_id

  validates :gca, presence: { message: "Every load must have a GCA" }
  validates :pilot, presence: { message: "Pilot is required" }

  has_many :notifications, as: :resource
  has_many :slots, dependent: :destroy

  counter_culture :dropzone


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
      mark_as_landed
    # Change state to boarding call and notify everyone
    elsif saved_change_to_dispatch_at? && dispatch_at
      dispatch

    # Change state back to open if dispatch_at is reset
    elsif saved_change_to_dispatch_at? && dispatch_at.nil?
      reopen
    end
  end

  def notify!
    return unless saved_change_to_dispatch_at?
    return unless dispatch_at_was.nil?
    return if dispatch_at.nil?
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

  def ready?
    return false unless gca.present?
    return false unless load_master.present?
    return false unless plane.present?
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

  private
    def set_load_number
      Time.use_zone(dropzone.time_zone) do
        assign_attributes(load_number: plane.dropzone.loads_today.count + 1)
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
