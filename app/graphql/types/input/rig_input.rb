# frozen_string_literal: true

module Types
  module Input
    class RigInput < Types::BaseInputObject
      argument :name, String, required: false
      argument :make, String, required: false
      argument :model, String, required: false
      argument :serial, String, required: false
      argument :pack_value, Int, required: false
      argument :repack_expires_at, Int, required: false
      argument :maintained_at, Int, required: false
      argument :dropzone_id, Int, required: false
      argument :user_id, Int, required: false
      argument :rig_type, String, required: false,
      description: Rig.rig_types.keys.join(" / ")
      argument :is_public, Boolean, required: false
      argument :canopy_size, Int, required: false
    end
  end
end
