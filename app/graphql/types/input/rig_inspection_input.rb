module Types
  module Input
    class RigInspectionInput < Types::BaseInputObject
      argument :dropzone_id, Int, required: false
      argument :rig_id, Int, required: false
      argument :definition, String, required: false
      argument :is_ok, Boolean, required: false
    end
  end
end