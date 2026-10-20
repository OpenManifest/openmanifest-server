# frozen_string_literal: true

module Mutations::Setup::Equipment
  class UpdateEquipment < Mutations::BaseMutation
    include OfficeAccess

    field :errors, [String], null: true
    field :field_errors, [Types::System::FieldError], null: true
    field :equipment, Types::Equipment::Equipment, null: true

    argument :attributes, Types::Input::EquipmentInput, required: true
    argument :id, Int, required: false

    def resolve(attributes:, id: nil)
      model = Equipment.find(id)

      # An item never moves to another operator or owner
      if attributes[:packing_card]
        Support::ImageUpload.attach(model.packing_card, attributes[:packing_card], name: "packing-card")
      end
      assign_equipment(model, attributes, kind: attributes[:kind_id] ? EquipmentKind.kept.find(attributes[:kind_id]) : nil)
      model.save!

      {
        equipment: model.reload,
        errors: nil,
        field_errors: nil,
      }
    rescue Support::ImageUpload::Invalid => e
      { equipment: nil, field_errors: [{ field: "packing_card", message: e.message }], errors: [e.message] }
    rescue ActiveRecord::RecordInvalid => invalid
      # Failed save, return the errors to the client
      {
        equipment: nil,
        field_errors: invalid.record.errors.messages.map { |field, messages| { field: field, message: messages.first } },
        errors: invalid.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotSaved => error
      # Failed save, return the errors to the client
      {
        equipment: nil,
        field_errors: nil,
        errors: error.record.errors.full_messages,
      }
    rescue ActiveRecord::RecordNotFound => error
      {
        equipment: nil,
        field_errors: nil,
        errors: [error.message],
      }
    end

    def authorized?(id: nil, attributes: nil)
      equipment = Equipment.find(id)

      if equipment.user_id && equipment.user_id != context[:current_resource].id && !staff_of_member?(equipment.user)
        [
          false, {
            errors: [
              "You can't update other users' equipment",
            ],
          },
        ]
      elsif equipment.operator_id && !context[:current_resource].can?(:updateOperatorEquipment, operator_id: equipment.operator_id)
        [
          false, {
            errors: [
              "You can't update equipment for this operator",
            ],
          },
        ]
      else
        true
      end
    end
  end
end
