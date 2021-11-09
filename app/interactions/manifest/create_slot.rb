# frozen_string_literal: true

require "active_interaction"

class Manifest::CreateSlot < ActiveInteraction::Base
  integer :load_id
  integer :dropzone_user_id
  integer :ticket_type_id
  integer :jump_type_id
  integer :rig_id, default: nil
  float :exit_weight
  string :passenger_name, default: nil
  float :passenger_exit_weight, default: nil
  array :extra_ids, default: nil do
    integer
  end

  validates :dropzone_user_id, :ticket_type_id, :jump_type_id, :exit_weight, presence: true

  def execute
    build_slot
    set_tandem_passenger
    check_double_manifesting
    check_allowed_jump_type
    check_credits if dropzone.is_credit_system_enabled?
    return if errors.any?

    errors.merge!(@model.errors) unless @model.save
    create_order if dropzone.is_credit_system_enabled?
    errors.merge!(@model.errors) unless @model.save
    @model
  end

  def build_slot
    @model = Slot.find_or_initialize_by(
      dropzone_user: dropzone_user,
      load_id: load_id
    )

    @model.assign_attributes(
      dropzone_user_id: dropzone_user_id,
      ticket_type_id: ticket_type_id,
      jump_type_id: jump_type_id,
      rig_id: rig_id
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
        dropzone: dropzone
      )

      @model.passenger_slot = Slot.create(
        load: plane_load,
        passenger: passenger,
        exit_weight: passenger_exit_weight,
        ticket_type: @model.ticket_type,
        jump_type: @model.jump_type
      )
    end
  end

  def check_credits
    credits = dropzone_user.credits || 0

    errors.add(:base, "Not enough credits to manifest for this jump") if total_cost > credits
  end

  def check_allowed_jump_type
    unless jump_type.allowed_for?(dropzone_user)
      errors.add(:jump_type_id, "User cannot be manifested for #{jump_type.name} jumps")
    end
  end

  def check_double_manifesting
    # Check if the user is manifest on any loads that have
    # not yet been dispatched
    if Slot.exists?(load: dropzone.loads_today.active, dropzone_user: dropzone_user)
      if !dropzone_user.reload.can?(:createDoubleSlot)
        errors.add(:base, "You're not allowed to double-manifest")
      end
    end
  end

  def create_order
    compose(
      Transactions::Purchase,
      dropzone: dropzone,
      buyer: dropzone_user,
      seller: dropzone,
      purchasable: @model
    )
  end

  private
    def plane_load
      Load.find(load_id)
    end

    def dropzone
      plane_load.plane.dropzone
    end

    def dropzone_user
      dropzone.dropzone_users.find_by(id: dropzone_user_id)
    end

    def ticket_type
      dropzone.ticket_types.find_by(id: ticket_type_id)
    end

    def jump_type
      JumpType.find_by(id: jump_type_id)
    end

    def total_cost
      # Find extras
      extra_cost = Extra.where(
        dropzone: dropzone,
        id: extra_ids
      ).map(&:cost).reduce(&:sum)

      extra_cost ||= 0

      ticket_type.cost + extra_cost
    end
end
