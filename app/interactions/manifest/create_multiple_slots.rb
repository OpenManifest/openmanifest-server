# frozen_string_literal: true

require "active_interaction"

class Manifest::CreateMultipleSlots < ApplicationInteraction
  record :load
  record :ticket_type
  record :jump_type
  integer :group_number, default: nil
  # Add-ons bought for every member of the group
  array :extra_ids, default: nil do
    integer
  end
  date_time :created_at, default: -> { DateTime.current }
  array :users do
    hash do
      record :dropzone_user
      float :exit_weight
      record :rig, default: nil
      string :passenger_name, default: nil
      float :passenger_exit_weight, default: nil
    end
  end

  validates :ticket_type, :jump_type, :users, presence: true

  steps :lock_load_and_members,
        :check_available_slots,
        :check_allowed_jump_type,
        :check_credits,
        :create_slots

  # Capacity and credits are checked against rows nobody else can change until this transaction ends (BUG-020,
  # BUG-023). Lock order: the load, then the members by id.
  def lock_load_and_members
    load.lock!
    dropzone_users.sort_by(&:id).each(&:lock!)
  end

  # The whole group gets one group number (BUG-027)
  def create_slots
    group = group_number || plane_load.next_group_number

    users.map do |user|
      compose(
        ::Manifest::CreateSlot,
        group_number: group,
        access_context: access_context,
        created_at: created_at,
        group_includes_self: group_includes_self?,
        ticket_type: ticket_type,
        jump_type: jump_type,
        extra_ids: extra_ids,
        load: load,
        **user
      )
    end
    load.reload
  end

  def group_includes_self?
    access_context&.subject.present? && users.any? { |user| user[:dropzone_user] == access_context.subject }
  end

  def check_available_slots
    # Check how many users we're manifesting, and return
    # an error if there aren't enough slots on this load
    slots_expected = users.sum { |user| user[:passenger_name] ? 2 : 1 }

    return unless slots_expected > plane_load.reload.available_slots
    errors.add(:base, "Only #{plane_load.available_slots} slots available")
  end

  def check_credits
    return unless dropzone.is_credit_system_enabled?

    cost = ticket_type.cost_cents.to_i + Extra.where(dropzone: dropzone, id: extra_ids).sum(:cost_cents)
    users.each do |user|
      next unless cost > (user[:dropzone_user].credits_cents || 0)

      errors.add(:base, "#{user[:dropzone_user].user.name} doesn't have enough credits to manifest for this jump")
      errors.add(:credits, "Not enough credits to manifest #{user[:dropzone_user].user.name}")
    end
  end

  def check_allowed_jump_type
    return if jump_type.allowed_for?(dropzone_users)
    errors.add(:jump_type_id, "Not all members are licensed for #{jump_type.name} jumps")
  end

  def check_double_manifesting
    # Check if the user is manifest on any loads that have
    # not yet been dispatched
    Slot.where(load: dropzone.loads.on(dropzone.today).active, dropzone_user: dropzone_users).each do |existing_slot|
      if !existing_slot.dropzone_user.can?(:createDoubleSlot)
        errors.add(:base, "#{existing_slot.dropzone_user.user.name} can not be double-manifested")
      end
    end
  end

  private

  def dropzone_users
    users.pluck(:dropzone_user)
  end

  def plane_load
    load.reload
  end

  def dropzone
    plane_load.plane.dropzone
  end
end
