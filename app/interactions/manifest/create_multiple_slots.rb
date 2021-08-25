# frozen_string_literal: true

require 'active_interaction'

class Manifest::CreateMultipleSlots < ActiveInteraction::Base
  integer :load_id
  integer :ticket_type_id
  integer :jump_type_id
  array :users do
    hash do
      integer :dropzone_user_id
      float :exit_weight
      integer :rig_id, default: nil
      string :passenger_name, default: nil
      float :passenger_exit_weight, default: nil
      array :extra_ids, default: nil do
        integer
      end
    end
  end

  validates :users, :ticket_type_id, :jump_type_id, :users, presence: true

  def execute
    check_available_slots
    check_allowed_jump_type
    check_credits if dropzone.is_credit_system_enabled?
    return if errors.any?

    users.each do |user|
      compose(
        ::Manifest::CreateSlot,
        ticket_type_id: ticket_type_id,
        jump_type_id: jump_type_id,
        load_id: load_id,
        **user
      )
    end

    plane_load.reload
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
    users.each do |user|
      cost = ticket_type.cost
      if user[:extra_ids]
        cost += Extra.where(
          dropzone: dropzone,
          id: user[:extra_ids]
        ).map(&:cost).reduce(&:sum)
      end

      dz_user = dropzone_users.find_by(id: user[:dropzone_user_id])

      if cost > dz_user.credits
        errors.add(:base, "#{dz_user.user.name} doesn't have enough credits to manifest for this jump")
        errors.add(:credits, "Not enough credits to manifest #{dz_user.user.name}")
      end
    end
  end

  def check_allowed_jump_type
    unless jump_type.allowed_for?(dropzone_users)
      errors.add(:jump_type_id, "Not all members are licensed for #{jump_type.name} jumps")
    end
  end

  private

  def dropzone_users
    dropzone.dropzone_users.where(id: users.pluck(:dropzone_user_id))
  end

  def next_group_number
    current_highest_group_number + 1
  end

  def current_highest_group_number
    plane_load.slots.maximum(:group_number) || 0
  end

  def plane_load
    Load.find(load_id)
  end

  def dropzone
    plane_load.plane.dropzone
  end

  def ticket_type
    dropzone.ticket_types.find_by(id: ticket_type_id)
  end

  def jump_type
    JumpType.find_by(id: jump_type_id)
  end
end
