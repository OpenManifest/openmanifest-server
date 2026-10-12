# frozen_string_literal: true

module Types
  module Input
    class GhostInput < Types::Base::Input
      argument :name, String, required: true
      argument :email, String, required: true
      argument :phone, String, required: false
      argument :body_mass_kg, Float, required: true
      argument :operator, Integer, required: true,
                                   prepare: -> (value, ctx) { ::Operator.find_by(id: value) }
      argument :role, Integer, required: true,
                               prepare: -> (value, ctx) { ::UserRole.find_by(id: value) }
      argument :license, Integer, required: false,
                                  prepare: -> (value, ctx) { ::License.find_by(id: value) }
      argument :federation_number, String, required: false
    end
  end
end
