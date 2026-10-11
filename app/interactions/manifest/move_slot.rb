# frozen_string_literal: true

require "active_interaction"

class Manifest::MoveSlot < ApplicationInteraction
  attr_accessor :model

  record :source_slot, class: Slot
  record :target_slot, class: Slot, default: nil
  record :target_load, class: Load, default: nil

  validate :same_dropzone

  steps :open_with_room,
        :affordable?,
        :move_slot,
        :validate,
        :update_order,
        :save,
        :broadcast_subscription,
        # Return value
        :affected_loads

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: source_slot,
      action: :created,
      access_level: :user,
      created_at: DateTime.current,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.user.name} moved #{source_slot.dropzone_user.user.name} from load ##{source_slot.load.load_number} to load ##{destination_load.load_number}"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: source_slot,
      created_at: DateTime.current,
      action: :created,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.user.name} failed to move #{source_slot.dropzone_user.user.name} from load ##{load.load_number}",
      details: errors.full_messages.join(", ")
    )
  end

  def move_slot
    source_slot.assign_attributes(
      load: destination_load,
      ticket_type: target_slot&.ticket_type || source_slot.ticket_type,
      jump_type: target_slot&.jump_type || source_slot.jump_type,
      group_number: target_slot&.group_numner || source_slot.group_number
    )
  end

  # Push update to GraphQL
  def broadcast_subscription
    source_slot.load.broadcast_update if source_slot
    target_slot.load.broadcast_update if target_slot
    target_load.broadcast_update if target_load
  end

  def affordable?
    return unless source_slot.load.plane.dropzone.is_credit_system_enabled?
    # Check the cost of the current slot
    user_funds = source_slot.cost + source_slot.dropzone_user.credits

    # Check if the user has enough credits
    # to manifest for this jump (taking into consideration the cost)
    # of the previous slot
    errors.add(:base, "Not enough credits to manifest for this jump") if source_slot.cost > user_funds
  end

  def validate
    errors.merge!(source_slot.errors) unless source_slot.valid?
  end

  def save
    errors.merge!(source_slot.errors) unless source_slot.save
  end

  def update_order
    return unless source_slot.order

    # Refund the original order
    compose(
      Transactions::Refund,
      order: source_slot.order,
      access_context: access_context
    )

    # Create a new order
    compose(
      Transactions::Purchase,
      buyer: source_slot.dropzone_user,
      seller: access_context.dropzone,
      purchasable: source_slot,
      access_context: access_context
    )
  end

  def affected_loads
    [source_slot.load.reload, destination_load.reload]
  end

  # Moving someone else's slot needs updateUserSlot, your own updateSlot (BUG-007)
  def required_permissions
    own = access_context&.subject.present? && access_context.subject == source_slot.dropzone_user
    return { updateSlot: "You don't have permissions to move your slot (missing updateSlot)" } if own

    { updateUserSlot: "You don't have permissions to move other users (missing updateUserSlot)" }
  end

  # The target must be open and have room for the slot (and its passenger): slot validations only run on create (BUG-092)
  def open_with_room
    return if destination_load == source_slot.load

    unless destination_load.open? || destination_load.boarding_call?
      errors.add(:base, "Load ##{destination_load.load_number} is not open")
      return
    end

    capacity = destination_load.max_slots || destination_load.plane.max_slots
    needed = source_slot.has_passenger? ? 2 : 1
    errors.add(:base, "No slots available on load ##{destination_load.load_number}") if capacity - destination_load.slots.count < needed
  end

  private

  # Both loads must belong to the dropzone the caller acts in
  def same_dropzone
    dropzone_id = access_context&.dropzone&.id
    loads = [source_slot.load, destination_load].compact
    errors.add(:base, "The slot and the load must belong to the same dropzone") unless loads.present? && loads.all? { |load| load.plane.dropzone_id == dropzone_id }
  end

  def destination_load
    return target_slot.load if target_slot
    target_load
  end
end
