# frozen_string_literal: true

module Types
  module Input
    class SlotInput < Types::BaseInputObject
      argument :dropzone_user_id, Int, required: false
      argument :ticket_type_id, Int, required: false
      argument :jump_type_id, Int, required: false
      argument :load_id, Int, required: false
      argument :rig_id, Int, required: false
      argument :exit_weight, Float, required: false
      argument :extra_ids, [Int], required: false

      argument :user_group, [Types::Input::SlotUser], required: false

      argument :passenger_name, String, required: false
      argument :passenger_exit_weight, Float, required: false
    end
  end
end
