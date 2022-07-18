# frozen_string_literal: true

module Types
  module Input
    class RigInspectionInput < Types::BaseInputObject
      argument :dropzone, Int, required: false,
               prepare: -> (value, ctx) { Dropzone.find(value) }
      argument :rig, Int, required: false,
               prepare: -> (value, ctx) { Rig.find(value) }
      argument :definition, String, required: false
      argument :is_ok, Boolean, required: false
    end
  end
end
