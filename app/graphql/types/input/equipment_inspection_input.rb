# frozen_string_literal: true

module Types
  module Input
    class EquipmentInspectionInput < Types::Base::Input
      argument :operator, GraphQL::Types::ID, required: false,
                                              prepare: -> (value, ctx) { ::Operator.find_by(id: value) }
      argument :equipment, GraphQL::Types::ID, required: false,
                                               prepare: -> (value, ctx) { ::Equipment.find_by(id: value) }
      argument :definition, String, required: false
      argument :is_ok, Boolean, required: false
    end
  end
end
