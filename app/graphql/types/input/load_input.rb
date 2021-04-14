module Types
  module Input
    class LoadInput < Types::BaseInputObject
      argument :dispatch_at, Int, required: false
      argument :name, String, required: false
      argument :has_landed, Boolean, required: false
      argument :pilot_id, Int, required: false
    end
  end
end