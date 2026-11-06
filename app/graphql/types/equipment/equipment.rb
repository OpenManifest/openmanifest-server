# frozen_string_literal: true

module Types::Equipment
  class Equipment < Types::Base::Object
    implements Types::Interfaces::Polymorphic
    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: true
    field :make, String, null: true
    field :model, String, null: true
    field :serial, String, null: true
    async_field :kind, Types::Equipment::EquipmentKind, null: false
    field :ownership, String, null: false, description: "personal (a member's own) or operator (kept by the operator, rented out when public)"
    field :attributes, GraphQL::Types::JSON, null: false, method: :properties,
                                             description: "The values of the kind's attributes; canopy size is in square metres"
    field :service_due_at, Int, null: true
    field :maintained_at, Int, null: true
    field :is_public, Boolean, null: false
    field :in_service, Boolean, null: false, method: :in_service?, description: "False once the service date has passed"
    timestamp_fields
    async_field :operator, Types::OperatorType, null: true
    async_field :owner, Types::Users::User, null: true, method: :user
    field :packing_card, String, null: true
    def packing_card
      return nil unless object.packing_card.attached?
      Rails.application.routes.url_helpers.url_for(object.packing_card)
    end

    field :equipment_inspections, Types::Equipment::EquipmentInspection, null: true do
      argument :operator_id, GraphQL::Types::ID, required: true
    end
    def equipment_inspections(operator_id: nil)
      operator = Operator.find_by(id: operator_id)
      return nil unless operator
      # The field is one inspection: the latest at this operator
      object.equipment_inspections.at_operator(operator).order(updated_at: :desc).first
    end
  end
end
