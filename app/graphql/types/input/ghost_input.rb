# frozen_string_literal: true

module Types
  module Input
    class GhostInput < Types::BaseInputObject
      argument :name, String, required: true
      argument :email, String, required: true
      argument :phone, String, required: false
      argument :exit_weight, Float, required: true
      argument :dropzone_id, Integer, required: true
      argument :role_id, Integer, required: true
      argument :license_id, Integer, required: false
    end
  end
end
