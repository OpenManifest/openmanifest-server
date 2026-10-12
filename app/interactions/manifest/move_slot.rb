# frozen_string_literal: true

require "active_interaction"

class Manifest::MoveSlot < ApplicationInteraction
  attr_accessor :model

  record :source_slot, class: Slot
  record :target_slot, class: Slot, default: nil
  record :target_load, class: Load, default: nil

  validate :same_operator

  steps :lock_rows,
        :open_with_room,
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
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} moved #{source_slot.membership.user.name} from load ##{source_slot.load.load_number} to load ##{destination_load.load_number}"
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
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} failed to move #{source_slot.membership&.user&.name || 'a guest'} from load ##{source_slot.load.load_number}",
      details: errors.full_messages.join(", ")
    )
  end

  # Capacity and credits are checked against rows nobody else can change until this transaction ends (BUG-020,
  # BUG-023). Lock order: the loads by id, then the member.
  def lock_rows
    [source_slot.load, destination_load].compact.uniq.sort_by(&:id).each(&:lock!)
    source_slot.reload
    source_slot.membership&.lock!
  end

  def move_slot
    source_slot.assign_attributes(
      load: destination_load,
      ticket_type: target_slot&.ticket_type || source_slot.ticket_type,
      activity_type: target_slot&.activity_type || source_slot.activity_type,
      group_number: target_slot&.group_number || source_slot.group_number
    )
  end

  # Push update to GraphQL
  def broadcast_subscription
    source_slot.load.broadcast_update if source_slot
    target_slot.load.broadcast_update if target_slot
    target_load.broadcast_update if target_load
  end

  def affordable?
    return unless source_slot.load.vehicle.operator.is_credit_system_enabled?
    # Check the cost of the current slot
    user_funds = source_slot.cost_cents + source_slot.membership.credits_cents.to_i

    # Check if the user has enough credits
    # to manifest for this jump (taking into consideration the cost)
    # of the previous slot
    errors.add(:base, "Not enough credits to manifest for this jump") if source_slot.cost_cents > user_funds
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
      buyer: source_slot.membership,
      seller: access_context.operator,
      purchasable: source_slot,
      access_context: access_context
    )
  end

  def affected_loads
    [source_slot.load.reload, destination_load.reload]
  end

  # Moving someone else's slot needs updateUserSlot, your own updateSlot (BUG-007)
  def required_permissions
    own = access_context&.subject.present? && access_context.subject == source_slot.membership
    if own
      message = if access_context.subject.manifest_desk_only?(:updateSlot)
                  Membership::MANIFEST_DESK_MESSAGE
                else
                  "You don't have permissions to move your slot (missing updateSlot)"
                end
      return { updateSlot: message }
    end

    { updateUserSlot: "You don't have permissions to move other users (missing updateUserSlot)" }
  end

  # The target must be open and have room for the slot (and its guest): slot validations only run on create (BUG-092)
  def open_with_room
    return if destination_load == source_slot.load

    unless destination_load.open? || destination_load.boarding?
      errors.add(:base, "Load ##{destination_load.load_number} is not open")
      return
    end

    capacity = destination_load.max_slots || destination_load.vehicle.capacity
    needed = source_slot.has_guest? ? 2 : 1
    errors.add(:base, "No slots available on load ##{destination_load.load_number}") if capacity - destination_load.slots.count < needed
  end

  private

  # Both loads must belong to the operator the caller acts in
  def same_operator
    operator_id = access_context&.operator&.id
    loads = [source_slot.load, destination_load].compact
    errors.add(:base, "The slot and the load must belong to the same operator") unless loads.present? && loads.all? { |load| load.vehicle.operator_id == operator_id }
  end

  def destination_load
    return target_slot.load if target_slot
    target_load
  end
end
