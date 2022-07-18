# frozen_string_literal: true

module Types
  module Input
    class LoadInput < Types::BaseInputObject
      argument :dispatch_at, Int, required: false
      argument :name, String, required: false
      argument :max_slots, Int, required: false
      argument :is_open, Boolean, required: false
      argument :has_landed, Boolean, required: false
      argument :pilot, Int, required: false,
               prepare: -> (value, ctx) { DropzoneUser.find(value) }
      argument :dispatch_at, Int, required: false
      argument :plane, Int, required: false,
               prepare: -> (value, ctx) { Plane.find(value) }
      argument :gca, Int, required: false,
               prepare: -> (value, ctx) { DropzoneUser.find(value) }
      argument :load_master, Int, required: false,
               prepare: -> (value, ctx) { DropzoneUser.find(value) }
      argument :state, Types::LoadStateType, required: false
    end
  end
end
