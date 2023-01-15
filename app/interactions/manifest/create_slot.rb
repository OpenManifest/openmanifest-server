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
  array :extra_ids, default: nil do
    integer
  end

  # Execution
  allow :createSlot

  steps :build_slot,
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

  def validate
    errors.merge!(@model.errors) unless @model.valid?
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
      group_number: group_number || load.next_group_number,
      jump_type: jump_type,
      rig: rig,
      created_by: access_context.subject,
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

  def create_order
    compose(
      Transactions::Purchase,
      buyer: dropzone_user,
      seller: access_context.dropzone,
      purchasable: model,
      access_context: access_context
    )
  end

  # Push update to GraphQL
  def broadcast_subscription
    load.broadcast_subscription
  end

  private

  def authorize
    dropzone = load.plane.dropzone
    action = if load.slots.exists?(dropzone_user: dropzone_user)
               "update"
             else
               "create"
             end

    if dropzone.loads.today.active.where(dropzone_user: dropzone_user)
      resource = if dropzone_user.id == access_context.subject.id
                   "Slot"
                 else
                   "UserSlot"
                 end

      return true if access_context.subject.can?("#{action}#{resource}")
      raise PermissionDenied, "You don't have permissions to manifest other users (missing #{"#{action}#{resource}"})"
    else
      resource = if dropzone_user.id == access_context.subject.id
                   "DoubleSlot"
                 else
                   "UserDoubleSlot"
                 end

      return true if access_context.can?("#{action}#{resource}")
      raise PermissionDenied, "You don't have permissions to double-manifest (missing #{"#{action}#{resource}"})"
    end
  end
end
