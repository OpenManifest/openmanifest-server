# frozen_string_literal: true

module Types::Manifest
  class Slot < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    implements Types::Interfaces::SellableItem

    def title
      "Slot on Load #{object.load.load_number}"
    end
    timestamp_fields
    field :id, GraphQL::Types::ID, null: false
    field :exit_weight, Integer, null: false
    def exit_weight
      object.exit_weight.to_i
    end
    field :group_number, Integer, null: false

    async_field :dropzone_user, Types::Users::DropzoneUser, null: true
    field :cost, Float, null: false

    async_field :ticket_type, Types::Dropzone::Ticket, null: true
    async_field :load, Types::Manifest::Load, null: false
    async_field :rig, Types::Equipment::Rig, null: true
    async_field :jump_type, Types::Meta::JumpType, null: true
    async_field :order, Types::Payments::Order, null: true
    field :wing_loading, Float, null: true

    field :passenger_name, String, null: true
    def passenger_name
      object.passenger_slot&.passenger&.name
    end

    field :passenger_exit_weight, Float, null: true
    def passenger_exit_weight
      object.passenger_slot&.exit_weight
    end

    field :extras, [Types::Dropzone::Tickets::Addon], null: true
  end
end
