# frozen_string_literal: true

module Types
  class SlotType < Types::BaseObject
    implements Types::AnyResourceType
    field :id, GraphQL::Types::ID, null: false
    field :created_at, Int, null: false
    field :created_at, Int, null: false
    field :exit_weight, Int, null: false
    def exit_weight
      object.exit_weight.to_i
    end
    field :group_number, Int, null: false

    field :dropzone_user, Types::DropzoneUserType, null: true
    field :user, Types::UserType, null: true
    field :cost, Integer, null: true

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
