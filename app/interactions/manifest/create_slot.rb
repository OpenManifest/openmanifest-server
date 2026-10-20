# frozen_string_literal: true

require "active_interaction"

class Manifest::CreateSlot < ApplicationInteraction
  attr_accessor :model

  record :load
  record :membership
  record :ticket_type
  record :activity_type
  # Where the slot goes (per-slot destinations); the ticket type's destination when left out
  record :destination, default: nil
  # The vehicle of the load the slot rides in; none: the load's (only) one
  record :load_vehicle, default: nil
  # The items the slot uses; each is the member's own or the operator's
  array :equipment_ids, default: nil do
    integer
  end
  integer :group_number, default: nil
  # Paid for already, so nothing is taken from the member's wallet; the ticket types that require an escort are (the guest
  # paid), and giving it either way needs createPrepaidSlot
  boolean :prepaid, default: nil
  float :body_mass_kg
  # The guests who ride with the member, the escort, on a ticket type that requires one (at most its `escort_capacity`);
  # given again for a member who is already on the load, they replace the guests there
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
  date_time :created_at, default: -> { DateTime.current }
  # Set when the member is manifested as part of a group that includes the person manifesting
  boolean :group_includes_self, default: false
  array :extra_ids, default: nil do
    integer
  end

  # Execution: a member needs createSlot to manifest themselves, createUserSlot to manifest somebody else (see
  # #required_permissions); everything must belong to the operator the caller acts in
  validate :same_operator, :extras_offered_with_ticket, :may_set_prepaid

  steps :lock_load_and_member,
        :build_slot,
        :set_guests,
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
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} manifested #{membership.user.name} on load ##{load.load_number}"
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
      operator: access_context.operator,
      created_by: access_context.subject,
      message: "#{access_context.user.name} failed to manifest #{membership.user.name} on load ##{load.load_number}",
      details: errors.full_messages.join(", ")
    )
  end

  # Capacity and credits are checked against rows nobody else can change until this transaction ends (BUG-020, BUG-023).
  # Lock order: the load, then the member (CreateMultipleSlots locks the load and then all members by id).
  def lock_load_and_member
    load.lock!
    load_vehicle&.lock!
    membership.lock!
  end

  # The slot's own rules, and those of what was chosen for it (the equipment: present, inspected, in service)
  def validate
    errors.merge!(@model.errors) unless @model.valid?
    Eligibility.failures(Eligibility::Context.new(@model), scopes: %i(manifest)).each { |result| errors.add(:base, result.message) }
  end

  def save
    unique_per_load { errors.merge!(@model.errors) unless @model.save }
  end

  def build_slot
    @model = load.slots.find_or_initialize_by(
      membership: membership,
    )

    @model.assign_attributes(
      created_at: created_at,
      membership: membership,
      ticket_type: ticket_type,
      group_number: group_number || load.next_group_number,
      activity_type: activity_type,
      created_by: access_context.subject,
      body_mass_kg: body_mass_kg
    )
    @model.prepaid = prepaid.nil? ? ticket_type.requires_escort? : prepaid
    @model.destination = destination if destination
    @model.load_vehicle = load_vehicle if load_vehicle
    @model.equipment = Equipment.kept.where(id: equipment_ids) unless equipment_ids.nil?
    # The add-ons are part of the slot's cost (Slot#cost), so they are set before the credit check and the order
    @model.extras = Extra.where(id: extra_ids) unless extra_ids.nil?
  end

  # The guests of the escort: the slots of the guests there already take the new values in order, more are added, the
  # surplus goes. The guests' slots are saved with the escort's.
  def set_guests
    return if guests.nil?

    unless ticket_type.requires_escort?
      errors.add(:guests, "#{ticket_type.name} does not take guests") if guests.any?
      return
    end

    existing = @model.guest_slots.to_a
    guests.each_with_index do |attributes, index|
      guest_slot = existing[index] || @model.guest_slots.build(load: load, ticket_type: ticket_type, activity_type: activity_type)
      guest_slot.assign_attributes(body_mass_kg: attributes[:body_mass_kg], load_vehicle: @model.load_vehicle, prepaid: @model.prepaid)
      guest_slot.destination = @model.destination if @model.destination
      guest = guest_slot.guest || Guest.new(operator: membership.operator)
      guest.assign_attributes(attributes.slice(:name, :body_mass_kg, :email, :phone, :date_of_birth, :emergency_contact))
      guest.save! if guest.persisted?
      guest_slot.guest = guest
    end
    existing.drop(guests.size).each { |surplus| @model.guest_slots.destroy(surplus) }
  end

  # The order saves the new slot with it; a prepaid slot has none (nothing is charged), so the slot is saved on its own
  def create_order
    return if @model.prepaid?

    unique_per_load do
      compose(
        Transactions::Purchase,
        buyer: membership,
        seller: access_context.operator,
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
    if manifesting_self?
      message = if access_context.subject.manifest_desk_only?(:createSlot)
                  Membership::MANIFEST_DESK_MESSAGE
                else
                  "You don't have permissions to manifest (missing createSlot)"
                end
      return { createSlot: message }
    end
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

  def may_set_prepaid
    return if prepaid.nil? || access_context&.can?(:createPrepaidSlot)

    errors.add(:base, "You don't have permissions to manifest a prepaid slot (missing createPrepaidSlot)")
  end

  def extras_offered_with_ticket
    return if extra_ids.blank?

    offered = ticket_type.extras.kept.where(id: extra_ids).pluck(:id)
    errors.add(:extras, "Not every add-on is offered with this ticket") unless offered.sort == extra_ids.uniq.sort
  end

  def manifesting_self?
    access_context&.subject.present? && membership.id == access_context.subject.id
  end

  # The load, the member and the ticket type must belong to the operator the caller acts in
  def same_operator
    operator_id = access_context&.operator&.id
    belongs = [load.operator_id, membership.operator_id, ticket_type.operator_id].all?(operator_id)
    errors.add(:base, "The load, the jumper and the ticket must belong to the same operator") unless belongs
  end
end
