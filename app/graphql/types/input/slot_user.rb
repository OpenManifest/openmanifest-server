# frozen_string_literal: true

module Types
  module Input
    class SlotUser < Types::Base::Input
      argument :id, Int, required: true
      argument :body_mass_kg, Float, required: true
      argument :equipment, [GraphQL::Types::ID], required: false,
                                                 prepare: -> (value, ctx) { ::Equipment.where(id: value) }
      argument :guests, [Types::Input::GuestInput], required: false
    end
  end
end
