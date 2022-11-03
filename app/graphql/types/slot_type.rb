# frozen_string_literal: true

module Types
  class SlotType < Types::BaseObject
    implements Types::AnyResourceType
    implements Types::SellableItemType

    def title
      "Slot on Load #{object.load.load_number}"
    end
    field :id, GraphQL::Types::ID, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :exit_weight, Integer, null: false
    def exit_weight
      object.exit_weight.to_i
    end
    field :group_number, Integer, null: false

    field :dropzone_user, Types::DropzoneUserType, null: true
    field :cost, Float, null: false

    field :ticket_type, Types::TicketTypeType, null: true
    field :load, Types::LoadType, null: false
    field :rig, Types::RigType, null: true
    field :jump_type, Types::JumpTypeType, null: true
    field :order, Types::OrderType, null: true
    field :wing_loading, Float, null: true

    field :passenger_name, String, null: true
    def passenger_name
      object.passenger_slot&.passenger&.name
    end

    field :passenger_exit_weight, Float, null: true
    def passenger_exit_weight
      object.passenger_slot&.exit_weight
    end

    field :extras, [Types::ExtraType], null: true
  end
end
