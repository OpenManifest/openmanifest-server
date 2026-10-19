# frozen_string_literal: true

require "active_interaction"

class Manifest::CreateMultipleSlots < ApplicationInteraction
  record :load
  record :ticket_type
  record :activity_type
  integer :group_number, default: nil
  # Add-ons bought for every member of the group
  array :extra_ids, default: nil do
    integer
  end
  date_time :created_at, default: -> { DateTime.current }
  array :users do
    hash do
      record :membership
      float :body_mass_kg
      array :equipment_ids, default: nil do
        integer
      end
      array :guests, default: nil do
        hash do
          string :name, default: nil
          float :body_mass_kg, default: nil
          string :email, default: nil
          string :phone, default: nil
          date :date_of_birth, default: nil
          string :emergency_contact, default: nil
        end
      end
    end
  end

  validates :ticket_type, :activity_type, :users, presence: true

  steps :lock_load_and_members,
        :check_available_slots,
        :check_allowed_activity_type,
        :check_credits,
        :create_slots

  # Capacity and credits are checked against rows nobody else can change until this transaction ends (BUG-020,
  # BUG-023). Lock order: the load, then the members by id.
  def lock_load_and_members
    load.lock!
    memberships.sort_by(&:id).each(&:lock!)
  end

  # The whole group gets one group number (BUG-027)
  def create_slots
    group = group_number || vehicle_load.next_group_number

    users.map do |user|
      compose(
        ::Manifest::CreateSlot,
        group_number: group,
        access_context: access_context,
        created_at: created_at,
        group_includes_self: group_includes_self?,
        ticket_type: ticket_type,
        activity_type: activity_type,
        extra_ids: extra_ids,
        load: load,
        **user
      )
    end
    load.reload
  end

  def group_includes_self?
    access_context&.subject.present? && users.any? { |user| user[:membership] == access_context.subject }
  end

  def check_available_slots
    # Check how many users we're manifesting, and return
    # an error if there aren't enough slots on this load
    slots_expected = users.sum { |user| 1 + user[:guests].to_a.size }

    return unless slots_expected > vehicle_load.reload.available_slots
    errors.add(:base, "Only #{vehicle_load.available_slots} slots available")
  end

  def check_credits
    return unless operator.is_credit_system_enabled?

    cost = ticket_type.cost_cents.to_i + Extra.where(operator: operator, id: extra_ids).sum(:cost_cents)
    users.each do |user|
      next unless cost > (user[:membership].credits_cents || 0)

      errors.add(:base, "#{user[:membership].user.name} doesn't have enough credits to manifest for this jump")
      errors.add(:credits, "Not enough credits to manifest #{user[:membership].user.name}")
    end
  end

  def check_allowed_activity_type
    return if activity_type.allowed_for?(memberships)
    errors.add(:activity_type_id, "Not all members are licensed for #{activity_type.name} jumps")
  end

  def check_double_manifesting
    # Check if the user is manifest on any loads that have
    # not yet been dispatched
    Slot.where(load: operator.loads.on(operator.today).active, membership: memberships).each do |existing_slot|
      if !existing_slot.membership.can?(:createDoubleSlot)
        errors.add(:base, "#{existing_slot.membership.user.name} can not be double-manifested")
      end
    end
  end

  private

  def memberships
    users.pluck(:membership)
  end

  def vehicle_load
    load.reload
  end

  def operator
    vehicle_load.operator
  end
end
