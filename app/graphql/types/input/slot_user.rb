# frozen_string_literal: true

module Types
  module Input
    class SlotUser < Types::Base::Input
      argument :id, Int, required: true
      argument :exit_weight, Float, required: true
      argument :rig, GraphQL::Types::ID, required: false,
                                         prepare: -> (value, ctx) { ::Rig.find_by(id: value) }
      argument :passenger_name, String, required: false
      argument :passenger_exit_weight, Float, required: false
    end
  end
end
