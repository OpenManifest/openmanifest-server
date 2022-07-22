# frozen_string_literal: true

module Types
  module Input
    class SlotInput < Types::BaseInputObject
      argument :dropzone_user, Int, required: false,
               prepare: -> (value, ctx) { DropzoneUser.find(value) }
      argument :ticket_type, Int, required: false,
               prepare: -> (value, ctx) { TicketType.find(value) }
      argument :jump_type, Int, required: false,
               prepare: -> (value, ctx) { JumpType.find(value) }
      argument :load, Int, required: false,
               prepare: -> (value, ctx) { Load.find(value) }
      argument :rig, Int, required: false,
               prepare: -> (value, ctx) { Rig.find(value) }
      argument :exit_weight, Float, required: false
      argument :extras, [Int], required: false,
               prepare: -> (value, ctx) { Extra.where(id: value) }

      argument :group_number, Int, required: false
      argument :user_group, [Types::Input::SlotUser], required: false

      argument :passenger_name, String, required: false
      argument :passenger_exit_weight, Float, required: false
    end
  end
end
