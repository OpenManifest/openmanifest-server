# frozen_string_literal: true

module Types
  module Input
    class RigInspectionInput < Types::Base::Input
      argument :operator, GraphQL::Types::ID, required: false,
                                              prepare: -> (value, ctx) { ::Operator.find_by(id: value) }
      argument :rig, GraphQL::Types::ID, required: false,
                                         prepare: -> (value, ctx) { ::Rig.find_by(id: value) }
      argument :definition, String, required: false
      argument :is_ok, Boolean, required: false
    end
  end
end
