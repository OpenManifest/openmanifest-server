# frozen_string_literal: true

module Types
  module Input
    class EquipmentInput < Types::Base::Input
      argument :kind_id, GraphQL::Types::ID, required: false,
                                             description: "The kind of the item; the operator's first kind when left out on create"
      argument :name, String, required: false
      argument :make, String, required: false
      argument :model, String, required: false
      argument :serial, String, required: false
      argument :attributes, GraphQL::Types::JSON, required: false,
                                                  description: "The values of the kind's attributes (canopy size in square metres); only those given change"
      argument :service_due_at, Int, required: false
      argument :maintained_at, Int, required: false
      argument :operator_id, Int, required: false
      argument :packing_card, String, required: false
      argument :user_id, Int, required: false
      argument :is_public, Boolean, required: false
    end
  end
end
