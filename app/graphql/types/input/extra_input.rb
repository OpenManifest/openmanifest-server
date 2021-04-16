# frozen_string_literal: true

module Types
  module Input
    class ExtraInput < Types::BaseInputObject
      argument :name, String, required: false
      argument :cost, Float, required: false
      argument :dropzone_id, Int, required: false
      argument :ticket_type_ids, [Int], required: false
    end
  end
end
