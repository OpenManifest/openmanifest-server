# frozen_string_literal: true

module Types
  module Input
    class SlotUser < Types::Base::Input
      argument :id, Int, required: true
      argument :body_mass_kg, Float, required: true
      argument :rig, GraphQL::Types::ID, required: false,
                                         prepare: -> (value, ctx) { ::Rig.find_by(id: value) }
      argument :guest_name, String, required: false
      argument :guest_body_mass_kg, Float, required: false
    end
  end
end
