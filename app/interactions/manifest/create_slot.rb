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
  date_time :created_at, default: DateTime.now
  float :passenger_exit_weight, default: nil
  array :extra_ids, default: nil do
    integer
  end

  # Execution
  allow :createSlot

  steps :build_slot,
        :check_slots,
        :set_tandem_passenger,
        :check_double_manifesting,
        :check_allowed_jump_type,
        :check_credits,
        :save,
        :create_order,
        :save,
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
      message: "#{access_context.subject.user.name} manifested #{dropzone_user.user.name} on load ##{load.load_number}"
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
      message: "#{access_context.subject.user.name} failed to manifest #{dropzone_user.user.name} on load ##{load.load_number}",
      details: errors.full_messages.join(", ")
    )
  end

  def save
    errors.merge!(@model.errors) unless @model.save
  end

  def build_slot
    @model = load.slots.find_or_initialize_by(
      dropzone_user: dropzone_user,
    )

    @model.assign_attributes(
      created_at: created_at,
      dropzone_user: dropzone_user,
      ticket_type: ticket_type,
      group_number: group_number,
      jump_type: jump_type,
      rig: rig,
      exit_weight: exit_weight
    )
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

  def check_slots
    errors.add(:base, "No slots available on this load") if load.available_slots < 1
  end

  def check_credits
    return unless dropzone_user.dropzone.is_credit_system_enabled?
    credits = dropzone_user.credits || 0

    errors.add(:base, "Not enough credits to manifest for this jump") if total_cost > credits
  end

  def check_allowed_jump_type
    return if jump_type.allowed_for?(dropzone_user)
    errors.add(:jump_type, "User cannot be manifested for #{jump_type.name} jumps")
  end

  def check_double_manifesting
    # Check if the user is manifest on any loads that have
    # not yet been dispatched
    return unless Slot.exists?(load: access_context.dropzone.loads_today.active, dropzone_user: dropzone_user)
    return if access_context.can?(:createDoubleSlot)
    errors.add(:base, "You're not allowed to double-manifest")
  end

  def create_order
    compose(
      Transactions::Purchase,
      buyer: dropzone_user,
      seller: access_context.dropzone,
      purchasable: model,
      access_context: access_context
    )
  end

  private
    def total_cost
      # Find extras
      extra_cost = Extra.where(
        dropzone: dropzone_user.dropzone,
        id: extra_ids
      ).map(&:cost).reduce(&:sum)

      extra_cost ||= 0

      ticket_type.cost + extra_cost
    end

    def authorize
      dropzone = load.plane.dropzone
      action = if load.slots.exists?(dropzone_user: dropzone_user)
        "update"
      else
        "create"
      end

      if dropzone.loads_today.active.where(dropzone_user: dropzone_user)
        resource = if dropzone_user.id != access_context.subject.id
          "UserSlot"
        else
          "Slot"
        end

        return true if access_context.subject.can?("#{action}#{resource}")
        raise PermissionDenied, "You don't have permissions to manifest other users (missing #{"#{action}#{resource}"})"
      else
        resource = if dropzone_user.id != access_context.subject.id
          "UserDoubleSlot"
        else
          "DoubleSlot"
        end


        return true if access_context.can?("#{action}#{resource}")
        raise PermissionDenied, "You don't have permissions to double-manifest (missing #{"#{action}#{resource}"})"
      end
    end
end
