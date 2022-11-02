# frozen_string_literal: true

require "active_interaction"

class Manifest::MoveSlot < ApplicationInteraction
  attr_accessor :model
  record :source_slot, class: Slot
  record :target_slot, class: Slot, default: nil
  record :target_load, class: Load, default: nil

  # Execution
  allow :updateSlot

  steps :affordable?,
        :move_slot,
        :validate,
        :update_order,
        :save,
        # Return value
        :affected_loads

  # Create events
  success do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      resource: model,
      action: :created,
      access_level: :user,
      created_at: created_at,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} moved #{dropzone_user.user.name} from load ##{slot.load.load_number} to load ##{destination_load.load_number}"
    )
  end

  # Create events
  error do
    compose(
      ::Activity::CreateEvent,
      access_context: access_context,
      level: :error,
      resource: model,
      created_at: created_at,
      action: :created,
      access_level: :admin,
      dropzone: access_context.dropzone,
      created_by: access_context.subject,
      message: "#{access_context.subject.user.name} failed to move #{dropzone_user.user.name} from load ##{load.load_number}",
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

  def affordable?
    return unless source_slot.load.plane.dropzone.is_credit_system_enabled?
    # Check the cost of the current slot
    user_funds = source_slot.cost + source_slot.dropzone_user.credits

    # Check if the user has enough credits
    # to manifest for this jump (taking into consideration the cost)
    # of the previous slot
    errors.add(:base, "Not enough credits to manifest for this jump") if slot.cost > user_funds
  end

  def validate
    errors.merge!(@model.errors) unless @model.valid?
  end

  def save
    errors.merge!(@model.errors) unless @model.save
  end

  def update_order
    return unless slot.order

    # Refund the original order
    compose(
      Transactions::Refund,
      order: slot.order,
      access_context: access_context
    )

    # Create a new order
    compose(
      Transactions::Purchase,
      buyer: dropzone_user,
      seller: access_context.dropzone,
      purchasable: model,
      access_context: access_context
    )
  end

  def affected_loads
    [source_slot.load, destination_load]
  end

  private
    def destination_load
      return target_slot.load if target_slot
      target_load
    end

    def authorize
      # Users are allowed to move their own slot
      return true if access_context.subject == source_slot.dropzone_user && access_context.subject.can?(:updateOwnSlot)
      return true if access_context.subject.can?(:updateUserSlot)
      raise PermissionDenied, "You don't have permissions to move other users"
    end
end
