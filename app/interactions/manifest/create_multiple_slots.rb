# frozen_string_literal: true

require "active_interaction"

class Manifest::CreateMultipleSlots < ApplicationInteraction
  record :load
  record :ticket_type
  record :jump_type
  array :users do
    hash do
      record :dropzone_user
      float :exit_weight
      record :rig, default: nil
      string :passenger_name, default: nil
      float :passenger_exit_weight, default: nil
      array :extras, default: nil do
        object class: Extra
      end
    end
  end

  validates :ticket_type, :jump_type, :users, presence: true

  steps :check_available_slots,
        :check_allowed_jump_type,
        :check_credits,
        :create_slots,
        # Return
        :plane_load

  def create_slots
    users.each do |user|
      compose(
        ::Manifest::CreateSlot,
        access_context: access_context,
        ticket_type: ticket_type,
        jump_type: jump_type,
        load: load,
        **user
      )
    end
  end

  def check_available_slots
    # Check how many users we're manifesting, and return
    # an error if there aren't enough slots on this load
    slots_expected = users.map { |user| user[:passenger_name] ? 2 : 1 }.sum

    if slots_expected > plane_load.reload.available_slots
      errors.add(:base, "Only #{plane_load.available_slots} slots available")
    end
  end

  def check_credits
    return unless dropzone.is_credit_system_enabled?
    users.each do |user|
      cost = ticket_type.cost
      if user[:extra_ids]
        cost += Extra.where(
          dropzone: dropzone,
          id: user[:extra_ids]
        ).map(&:cost).reduce(&:sum)
      end

      if cost > user[:dropzone_user].credits
        errors.add(:base, "#{user[:dropzone_user].user.name} doesn't have enough credits to manifest for this jump")
        errors.add(:credits, "Not enough credits to manifest #{user[:dropzone_user].user.name}")
      end
    end
  end

  def check_allowed_jump_type
    unless jump_type.allowed_for?(dropzone_users)
      errors.add(:jump_type_id, "Not all members are licensed for #{jump_type.name} jumps")
    end
  end

  def check_double_manifesting
    # Check if the user is manifest on any loads that have
    # not yet been dispatched
    Slot.where(load: dropzone.loads_today.active, dropzone_user: dropzone_users).each do |existing_slot|
      if !existing_slot.dropzone_user.can?(:createDoubleSlot)
        errors.add(:base, "#{existing_slot.dropzone_user.user.name} can not be double-manifested")
      end
    end
  end

  private
    def dropzone_users
      users.pluck(:dropzone_user)
    end

    def next_group_number
      current_highest_group_number + 1
    end

    def current_highest_group_number
      plane_load.slots.maximum(:group_number) || 0
    end

    def plane_load
      load
    end

    def dropzone
      plane_load.plane.dropzone
    end
end
