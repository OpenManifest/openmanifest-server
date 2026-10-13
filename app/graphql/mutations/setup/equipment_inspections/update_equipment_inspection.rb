# frozen_string_literal: true

module Mutations::Setup::EquipmentInspections
  class UpdateEquipmentInspection < Mutations::BaseMutation
    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :equipment_inspection, Types::Equipment::EquipmentInspection, null: true

    argument :attributes, Types::Input::EquipmentInspectionInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = EquipmentInspection.find(id)
      # An inspection keeps its member, equipment and operator; only the result and the form answers change
      model.assign_attributes(attributes.to_h.slice(:definition, :is_ok))

      model.save!

      {
        equipment_inspection: model,
        errors: nil,
        field_errors: nil,
      }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        equipment_inspection: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => invalid
      # Failed save, return the errors to the client
      {
        equipment_inspection: nil,
        field_errors: nil,
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        equipment_inspection: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(attributes: nil, id: nil)
      # The inspection's own operator, not the one the client says (BUG-009)
      inspection = EquipmentInspection.find_by(id: id)
      return [false, { errors: ["Equipment inspection not found"] }] unless inspection

      if context[:current_resource].can?(
        "actAsEquipmentInspector",
        operator_id: inspection.membership.operator_id
      )
        true
      else
        [
          false, {
            errors: [
              "You don't have permissions to inspect equipment",
            ],
          },
        ]
      end
    end
  end
end
