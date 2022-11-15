# frozen_string_literal: true

module Types
  module Input
    class SlotInput < Types::BaseInputObject
      argument :dropzone_user, GraphQL::Types::ID, required: false,
                                                   prepare: -> (value, ctx) { ::DropzoneUser.find_by(id: value) }
      argument :ticket_type, GraphQL::Types::ID, required: false,
                                                 prepare: -> (value, ctx) { ::TicketType.find_by(id: value) }
      argument :jump_type, GraphQL::Types::ID, required: false,
                                               prepare: -> (value, ctx) { ::JumpType.find_by(id: value) }
      argument :load, GraphQL::Types::ID, required: false,
                                          prepare: -> (value, ctx) { ::Load.find_by(id: value) }
      argument :rig, GraphQL::Types::ID, required: false,
                                         prepare: -> (value, ctx) { ::Rig.find_by(id: value) }
      argument :exit_weight, Float, required: false
      argument :extras, [GraphQL::Types::ID], required: false,
                                              prepare: -> (value, ctx) { ::Extra.where(id: value) }

      argument :group_number, Int, required: false
      argument :user_group, [Types::Input::SlotUser], required: false

      argument :passenger_name, String, required: false
      argument :passenger_exit_weight, Float, required: false
    end
  end
end
