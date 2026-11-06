# frozen_string_literal: true

module Mutations::Setup::EquipmentInspections
  class CreateEquipmentInspection < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :equipment_inspection, Types::Equipment::EquipmentInspection, null: true

    argument :attributes, Types::Input::EquipmentInspectionInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      mutate(
        ::Setup::Equipment::CreateEquipmentInspection,
        :equipment_inspection,
        operator: attributes[:operator],
        equipment: attributes[:equipment],
        definition: attributes[:definition],
        is_ok: attributes[:is_ok],
        access_context: access_context_for(attributes[:operator]),
      )
    end
  end
end
