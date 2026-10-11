# frozen_string_literal: true

require "active_interaction"

class Manifest::CreateSlot < ApplicationInteraction
  attr_accessor :model

  record :load
  record :dropzone_user
  record :ticket_type
  record :jump_type
  record :rig, default: nil
  integer :group_number, default: nil
  float :exit_weight
  string :passenger_name, default: nil
  date_time :created_at, default: -> { DateTime.current }
  float :passenger_exit_weight, default: nil
  # Set when the member is manifested as part of a group that includes the person manifesting
  boolean :group_includes_self, default: false
  array :extra_ids, default: nil do
    integer
  end

  # Execution: a member needs createSlot to manifest themselves, createUserSlot to manifest somebody else (see
  # #required_permissions); everything must belong to the dropzone the caller acts in
  validate :same_dropzone, :extras_offered_with_ticket

  steps :lock_load_and_member,
        :build_slot,
        :set_tandem_passenger,
        :validate,
        :create_order,
        :save,
        :broadcast_subscription,
        # Return value
        :model

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
      message: "#{access_context.user.name} manifested #{dropzone_user.user.name} on load ##{load.load_number}"
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
      message: "#{access_context.user.name} failed to manifest #{dropzone_user.user.name} on load ##{load.load_number}",
      details: errors.full_messages.join(", ")
    )
  end

  # Capacity and credits are checked against rows nobody else can change until this transaction ends (BUG-020, BUG-023).
  # Lock order: the load, then the member (CreateMultipleSlots locks the load and then all members by id).
  def lock_load_and_member
    load.lock!
    dropzone_user.lock!
  end

  def validate
    errors.merge!(@model.errors) unless @model.valid?
  end

  def save
    unique_per_load { errors.merge!(@model.errors) unless @model.save }
  end

  def build_slot
    @model = load.slots.find_or_initialize_by(
      dropzone_user: dropzone_user,
    )

    @model.assign_attributes(
      created_at: created_at,
      dropzone_user: dropzone_user,
      ticket_type: ticket_type,
      group_number: group_number || load.next_group_number,
      jump_type: jump_type,
      rig: rig,
      created_by: access_context.subject,
      exit_weight: exit_weight
    )
    # The add-ons are part of the slot's cost (Slot#cost), so they are set before the credit check and the order
    @model.extras = Extra.where(id: extra_ids) unless extra_ids.nil?
  end

  def set_tandem_passenger
    return unless @model.ticket_type.is_tandem? && passenger_name

    if @model.passenger_slot.present?
      @model.passenger_slot.passenger.update(
        name: passenger_name,
        exit_weight: passenger_exit_weight
      )
    else
      passenger = Passenger.find_or_create_by(
        name: passenger_name,
        exit_weight: passenger_exit_weight,
        dropzone: dropzone_user.dropzone
      )

      @model.passenger_slot = Slot.create(
        load: load,
        passenger: passenger,
        exit_weight: passenger_exit_weight,
        ticket_type: @model.ticket_type,
        jump_type: @model.jump_type
      )
    end
  end

  # The order saves the new slot with it
  def create_order
    unique_per_load do
      compose(
        Transactions::Purchase,
        buyer: dropzone_user,
        seller: access_context.dropzone,
        purchasable: model,
        access_context: access_context
      )
    end
  end

  # Push update to GraphQL
  def broadcast_subscription
    load.broadcast_update
  end

  # The permission to manifest this member: createSlot for yourself, createUserSlot for somebody else (BUG-006)
  def required_permissions
    return { createSlot: "You don't have permissions to manifest (missing createSlot)" } if manifesting_self?
    if group_includes_self && access_context&.can?(:createUserSlotWithSelf)
      return { createUserSlotWithSelf: "You don't have permissions to manifest a group (missing createUserSlotWithSelf)" }
    end

    { createUserSlot: "You don't have permissions to manifest other users (missing createUserSlot)" }
  end

  private

  # One person has one slot per load (unique index): report a violation instead of raising. The savepoint keeps the
  # surrounding transaction usable for the error event.
  def unique_per_load(&)
    Slot.transaction(requires_new: true, &)
  rescue ActiveRecord::RecordNotUnique
    errors.add(:base, "Already manifested on this load")
  end

  def extras_offered_with_ticket
    return if extra_ids.blank?

    offered = ticket_type.extras.kept.where(id: extra_ids).pluck(:id)
    errors.add(:extras, "Not every add-on is offered with this ticket") unless offered.sort == extra_ids.uniq.sort
  end

  def manifesting_self?
    access_context&.subject.present? && dropzone_user.id == access_context.subject.id
  end

  # The load, the member and the ticket type must belong to the dropzone the caller acts in
  def same_dropzone
    dropzone_id = access_context&.dropzone&.id
    belongs = [load.plane.dropzone_id, dropzone_user.dropzone_id, ticket_type.dropzone_id].all?(dropzone_id)
    errors.add(:base, "The load, the jumper and the ticket must belong to the same dropzone") unless belongs
  end
end
