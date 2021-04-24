# frozen_string_literal: true

module Types
  module Input
    class LoadInput < Types::BaseInputObject
      argument :dispatch_at, Int, required: false
      argument :name, String, required: false
      argument :max_slots, Int, required: false
      argument :is_open, Boolean, required: false
      argument :has_landed, Boolean, required: false
      argument :pilot_id, Int, required: false
      argument :dispatch_at, Int, required: false
      argument :plane_id, Int, required: false
      argument :gca_id, Int, required: false
      argument :load_master_id, Int, required: false
    end
  end
end
