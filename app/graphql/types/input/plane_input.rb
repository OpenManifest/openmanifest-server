# frozen_string_literal: true

module Types
  module Input
    class PlaneInput < Types::Base::Input
      argument :name, String, required: false
      argument :min_slots, Int, required: false
      argument :max_slots, Int, required: false
      argument :dropzone_id, Int, required: false
      argument :hours, Int, required: false
      argument :next_maintenance_hours, Int, required: false
      argument :registration, String, required: false
    end
  end
end
