# frozen_string_literal: true

module Types
  module Input
    class DropzoneInput < Types::BaseInputObject
      argument :name, String, required: true
      argument :banner, String, required: false
      argument :federation_id, Int, required: true
      argument :is_public, Boolean, required: false
      argument :primary_color, String, required: false
      argument :secondary_color, String, required: false
    end
  end
end
