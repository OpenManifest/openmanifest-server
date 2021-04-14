module Types
  module Input
    class TicketTypeInput < Types::BaseInputObject
      argument :currency, String, required: false
      argument :cost, Float, required: false
      argument :name, String, required: false
      argument :altitude, Int, required: false
      argument :allow_manifesting_self, Boolean, required: false
      argument :dropzone_id, Int, required: false
      
      argument :extra_ids, [Int], required: false
    end
  end
end