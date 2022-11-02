# frozen_string_literal: true

module Types
  module Input
    class RigInspectionInput < Types::BaseInputObject
      argument :dropzone, Int, required: false,
               prepare: -> (value, ctx) { Dropzone.find_by(id: value) }
      argument :rig, Int, required: false,
               prepare: -> (value, ctx) { Rig.find_by(id: value) }
      argument :definition, String, required: false
      argument :is_ok, Boolean, required: false
    end
  end
end
