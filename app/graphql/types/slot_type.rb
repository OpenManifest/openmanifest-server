# frozen_string_literal: true

module Types
  class SlotType < Types::BaseObject
    field :id, GraphQL::Types::ID, null: false
    field :created_at, Int, null: false
    field :created_at, Int, null: false
    field :exit_weight, Float, null: false

    field :user, Types::UserType, null: true
    field :ticket_type, Types::TicketTypeType, null: true
    field :load, Types::LoadType, null: false
    field :rig, Types::RigType, null: true
    field :jump_type, Types::JumpTypeType, null: true
    field :wing_loading, Float, null: true

    field :extras, [Types::ExtraType], null: true
  end
end
